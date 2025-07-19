/*

import Elm.Kernel.Debug exposing (crash)
import Elm.Kernel.Json exposing (run, wrap, unwrap, errorToString)
import Elm.Kernel.List exposing (Cons, Nil)
import Elm.Kernel.Process exposing (sleep)
import Elm.Kernel.Scheduler exposing (andThen, binding, rawSend, rawSpawn, receive, send, succeed)
import Elm.Kernel.Utils exposing (Tuple0)
import Result exposing (isOk)

*/

import {
	Empty,
	NonEmpty,
	Ok,
} from '../gleam.mjs';
import {
	_Debug_crash as __Debug_crash,
} from './debug.ffi.mjs';
import {
	_Json_run as __Json_run,
	_Json_unwrap as __Json_unwrap,
	_Json_wrap as __Json_wrap,
} from './json.ffi.mjs';
import {
	_Process_sleep as __Process_sleep,
} from './process.ffi.mjs';
import {
	_Scheduler_andThen as __Scheduler_andThen,
	_Scheduler_binding as __Scheduler_binding,
	_Scheduler_rawSend as __Scheduler_rawSend,
	_Scheduler_rawSpawn as __Scheduler_rawSpawn,
	_Scheduler_receive as __Scheduler_receive,
	_Scheduler_send as __Scheduler_send,
	_Scheduler_succeed as __Scheduler_succeed,
} from './scheduler.ffi.mjs';
import {
	automatically_registered_effect_manager as task_automatically_registered_effect_manager,
} from './task.mjs';

var __2_SELF = 0;
var __2_LEAF = 1;
var __2_NODE = 2;
var __2_MAP = 3;


// PROGRAMS


var _Platform_worker = function(flagDecoder, init, update, subscriptions, passedEffectManagers) { return function(args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		init,
		update,
		subscriptions,
		passedEffectManagers,
		function() { return function() {} }
	);
}};



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, passedEffectManagers, stepperBuilder)
{
	var effectManagers = {};
	var taskEffectManager = task_automatically_registered_effect_manager();
	effectManagers[taskEffectManager.home] = taskEffectManager.raw_effect_manager;

	for (var manager of passedEffectManagers)
	{
		_Platform_checkPortName(manager.home, effectManagers);
		effectManagers[manager.home] = manager.raw_effect_manager;
	}

	var result = __Json_run(flagDecoder, __Json_wrap(args ? args['flags'] : undefined));
	result instanceof Ok || __Debug_crash(2 /**__DEBUG/, __Json_errorToString(result[0]) /**/);
	var managers = {};
	var initPair = init(result[0]);
	var model = initPair[0];
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp, effectManagers);

	function sendToApp(msg, viewMetadata)
	{
		var pair = update(msg, model);
		stepper(model = pair[0], viewMetadata);
		_Platform_enqueueEffects(managers, pair[1], subscriptions(model), effectManagers);
	}

	_Platform_enqueueEffects(managers, initPair[1], subscriptions(model), effectManagers);

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


function _Platform_setupEffects(managers, sendToApp, effectManagers)
{
	var ports;

	// setup all necessary effect managers
	for (var key in effectManagers)
	{
		var manager = effectManagers[key];

		if (manager.__portSetup)
		{
			ports = ports || {};
			ports[key] = manager.__portSetup(key, sendToApp, effectManagers);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		__init: init,
		__onEffects: onEffects,
		__onSelfMsg: onSelfMsg,
		__cmdMap: cmdMap,
		__subMap: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		__sendToApp: sendToApp,
		__selfProcess: undefined
	};

	var onEffects = info.__onEffects;
	var onSelfMsg = info.__onSelfMsg;
	var cmdMap = info.__cmdMap;
	var subMap = info.__subMap;

	function loop(state)
	{
		return __Scheduler_andThen(loop, __Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === __2_SELF)
			{
				return onSelfMsg(router, value, state);
			}

			return cmdMap && subMap
				? onEffects(router, value.__cmds, value.__subs, state)
				: onEffects(router, cmdMap ? value.__cmds : value.__subs, state);
		}));
	}

	return router.__selfProcess = __Scheduler_rawSpawn(__Scheduler_andThen(loop, info.__init));
}



// ROUTING


var _Platform_sendToApp = function(router, msg)
{
	return __Scheduler_binding(function(callback)
	{
		router.__sendToApp(msg);
		callback(__Scheduler_succeed(undefined));
	});
};


var _Platform_sendToSelf = function(router, msg)
{
	return __Scheduler_send(router.__selfProcess, {
		$: __2_SELF,
		a: msg
	});
};



// BAGS


function _Platform_leaf(home, value)
{
	return {
		$: __2_LEAF,
		__home: home,
		__value: value
	};
}


function _Platform_batch(list)
{
	return {
		$: __2_NODE,
		__bags: list
	};
}


var _Platform_map = function(bag, tagger)
{
	return {
		$: __2_MAP,
		__func: tagger,
		__bag: bag
	}
};



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag, effectManagers)
{
	_Platform_effectsQueue.push({ __managers: managers, __cmdBag: cmdBag, __subBag: subBag, __effectManagers: effectManagers });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.__managers, fx.__cmdBag, fx.__subBag, fx.__effectManagers);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag, effectManagers)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null, effectManagers);
	_Platform_gatherEffects(false, subBag, effectsDict, null, effectManagers);

	for (var home in managers)
	{
		__Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { __cmds: new Empty, __subs: new Empty }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers, effectManagers)
{
	switch (bag.$)
	{
		case __2_LEAF:
			var home = bag.__home;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.__value, effectManagers);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case __2_NODE:
			for (var subBag of bag.__bags)
			{
				_Platform_gatherEffects(isCmd, subBag, effectsDict, taggers, effectManagers);
			}
			return;

		case __2_MAP:
			_Platform_gatherEffects(isCmd, bag.__bag, effectsDict, {
				__tagger: bag.__func,
				__rest: taggers
			}, effectManagers);
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value, effectManagers)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.__rest)
		{
			x = temp.__tagger(x);
		}
		return x;
	}

	var manager = effectManagers[home]; 

	if (!manager)
	{
		throw new Error('Missing effect manager for: ' + home);
	} 

	var map = isCmd ? manager.__cmdMap : manager.__subMap;

	return map(applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { __cmds: new Empty, __subs: new Empty };

	isCmd
		? (effects.__cmds = new NonEmpty(newEffect, effects.__cmds))
		: (effects.__subs = new NonEmpty(newEffect, effects.__subs));

	return effects;
}



// PORTS


function _Platform_checkPortName(name, effectManagers)
{
	if (effectManagers[name])
	{
		__Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(converter)
{
	return {
		__cmdMap: _Platform_outgoingPortMap,
		__converter: converter,
		__portSetup: _Platform_setupOutgoingPort
	};
}


var _Platform_outgoingPortMap = function(tagger, value) { return value; };


function _Platform_setupOutgoingPort(name, sendToApp, effectManagers)
{
	var subs = [];

	// CREATE MANAGER

	var init = __Process_sleep(0);

	effectManagers[name].__init = init;
	effectManagers[name].__onEffects = function(router, cmdList, state)
	{
		for (var cmd of cmdList)
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = __Json_unwrap(cmd);
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	};

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(converter)
{
	return {
		__subMap: _Platform_incomingPortMap,
		__converter: converter,
		__portSetup: _Platform_setupIncomingPort
	};
}


var _Platform_incomingPortMap = function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
};


function _Platform_setupIncomingPort(name, sendToApp, effectManagers)
{
	var subs = new Empty;
	var converter = effectManagers[name].__converter;

	// CREATE MANAGER

	var init = __Scheduler_succeed(null);

	effectManagers[name].__init = init;
	effectManagers[name].__onEffects = function(router, subList, state)
	{
		subs = subList;
		return init;
	};

	// PUBLIC API

	function send(incomingValue)
	{
		var result = __Json_run(converter, __Json_wrap(incomingValue));
		result instanceof Ok || __Debug_crash(4, name, result[0]);
		var value = result[0];
		for (var temp of subs)
		{
			sendToApp(temp(value));
		}
	}

	return { send: send };
}



export {
	_Platform_batch,
	_Platform_createManager,
	_Platform_incomingPort,
	_Platform_initialize,
	_Platform_leaf,
	_Platform_map,
	_Platform_outgoingPort,
	_Platform_sendToApp,
	_Platform_sendToSelf,
	_Platform_worker,
};
