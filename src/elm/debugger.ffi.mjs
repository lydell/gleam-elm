/*

import Debugger.Expando as Expando exposing (S, Primitive, Sequence, Dictionary, Record, Constructor, ListSeq, SetSeq, ArraySeq)
import Debugger.Main as Main exposing (getUserModel, wrapInit, wrapUpdate, wrapSubs, cornerView, popoutView, NoOp, UserMsg, Up, Down, toBlockerType, initialWindowWidth, initialWindowHeight)
import Debugger.Overlay as Overlay exposing (BlockNone, BlockMost)
import Elm.Kernel.Browser exposing (makeAnimator)
import Elm.Kernel.Debug exposing (crash)
import Elm.Kernel.Json exposing (wrap)
import Elm.Kernel.List exposing (Cons, Nil)
import Elm.Kernel.Platform exposing (initialize)
import Elm.Kernel.Scheduler exposing (binding, succeed)
import Elm.Kernel.Utils exposing (Tuple0, Tuple2, ap)
import Elm.Kernel.VirtualDom exposing (node, applyPatches, diff, doc, makeStepper, map, render, virtualize, divertHrefToApp)
import Json.Decode as Json exposing (map)
import List exposing (map, reverse)
import Maybe exposing (Just, Nothing)
import Set exposing (toList)
import Dict exposing (toList, empty, insert)
import Array exposing (toList)

*/

import {
	Empty,
	List,
	NonEmpty,
} from '../gleam.mjs';
import {
	default as Dict,
} from '../../gleam_stdlib/dict.mjs';
import {
	to_list as Dict_to_list,
} from '../../gleam_stdlib/gleam/dict.mjs';
import {
	append as __Utils_ap,
	map as __List_map,
} from '../../gleam_stdlib/gleam/list.mjs';
import {
	None,
	Some,
} from '../../gleam_stdlib/gleam/option.mjs';
import {
	new$ as Set_new,
	to_list as Set_to_list,
} from '../../gleam_stdlib/gleam/set.mjs';
import {
	empty as Array_empty,
	to_list as Array_to_list,
} from './array.mjs';
import {
	ArraySeq,
	Constructor,
	Dictionary,
	ListSeq,
	Primitive,
	Record,
	S,
	Sequence,
	SetSeq,
} from './debugger/expando.mjs';
import {
	_Debug_crash as __Debug_crash,
} from './debug.ffi.mjs';
import {
	_Browser_application,
	_Browser_makeAnimator,
} from './browser.ffi.mjs';
import {
	corner_view as __Main_cornerView,
	Down,
	get_user_model as __Main_getUserModel,
	initial_window_height as __Main_initialWindowHeight,
	initial_window_width as __Main_initialWindowWidth,
	NoOp,
	popout_view as __Main_popoutView,
	to_blocker_type as __Main_toBlockerType,
	Up,
	UserMsg,
	wrap_init as __Main_wrapInit,
	wrap_subs as __Main_wrapSubs,
	wrap_update as __Main_wrapUpdate,
} from './debugger/main.mjs';
import {
	BlockMost as __Overlay_BlockMost,
	BlockNone as __Overlay_BlockNone,
} from './debugger/overlay.mjs';
import {
	_Platform_initialize as __Platform_initialize,
} from './platform.ffi.mjs';
import {
	_Scheduler_binding as __Scheduler_binding,
	_Scheduler_succeed as __Scheduler_succeed,
} from './scheduler.ffi.mjs';
import {
	_VirtualDom_applyPatches as __VirtualDom_applyPatches,
	_VirtualDom_diff as __VirtualDom_diff,
	_VirtualDom_doc as __VirtualDom_doc,
	_VirtualDom_map as __VirtualDom_map,
	_VirtualDom_node as __VirtualDom_node,
	_VirtualDom_set_divertHrefToApp,
	_VirtualDom_set_doc,
	_VirtualDom_virtualize as __VirtualDom_virtualize,
} from './virtual_dom.ffi.mjs';

// The `Array` constructor is not exported.
var ElmArray = Array_empty().constructor;

// The `Set` constructor is not exported.
var GleamSet = Set_new().constructor;



// PROGRAMS


var _Debugger_element = function(flagDecoder, init, view, update, subscriptions, effectManagers) { return function(args)
{
	return __Platform_initialize(
		flagDecoder,
		args,
		__Main_wrapInit(_Debugger_popout(), init),
		__Main_wrapUpdate(update),
		__Main_wrapSubs(subscriptions),
		effectManagers,
		function(sendToApp, initialModel)
		{
			var domNode = args && args['node'] ? args['node'] : __Debug_crash(0);
			var currNode = __VirtualDom_virtualize(domNode);
			var currBlocker = __Main_toBlockerType(initialModel);
			var currPopout;

			var cornerNode = __VirtualDom_doc.createElement('div');
			domNode.parentNode.insertBefore(cornerNode, domNode.nextSibling);
			var cornerCurr = __VirtualDom_virtualize(cornerNode);

			initialModel.popout.__sendToApp = sendToApp;

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = __VirtualDom_map(view(__Main_getUserModel(model)), function(msg) { return new UserMsg(msg) });
				var patches = __VirtualDom_diff(currNode, nextNode);
				domNode = __VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;

				// update blocker

				var nextBlocker = __Main_toBlockerType(model);
				_Debugger_updateBlocker(currBlocker, nextBlocker);
				currBlocker = nextBlocker;

				// view corner

				var cornerNext = __Main_cornerView(model);
				var cornerPatches = __VirtualDom_diff(cornerCurr, cornerNext);
				cornerNode = __VirtualDom_applyPatches(cornerNode, cornerCurr, cornerPatches, sendToApp);
				cornerCurr = cornerNext;

				if (!model.popout.__doc)
				{
					currPopout = undefined;
					return;
				}

				// view popout

				_VirtualDom_set_doc(model.popout.__doc); // SWITCH TO POPOUT DOC
				currPopout || (currPopout = __VirtualDom_virtualize(model.popout.__doc.body));
				var nextPopout = __Main_popoutView(model);
				var popoutPatches = __VirtualDom_diff(currPopout, nextPopout);
				__VirtualDom_applyPatches(model.popout.__doc.body, currPopout, popoutPatches, sendToApp);
				currPopout = nextPopout;
				_VirtualDom_set_doc(document); // SWITCH BACK TO NORMAL DOC
			});
		}
	);
}};


var _Debugger_document = function(flagDecoder, init, view, update, subscriptions, effectManagers) { return function(args)
{
	var setup;
	if (flagDecoder.setup)
	{
		setup = flagDecoder.setup;
		flagDecoder = flagDecoder.flagDecoder;
	}
	return __Platform_initialize(
		flagDecoder,
		args,
		__Main_wrapInit(_Debugger_popout(), init),
		__Main_wrapUpdate(update),
		__Main_wrapSubs(subscriptions),
		effectManagers,
		function(sendToApp, initialModel)
		{
			var divertHrefToApp = setup && setup(function(x) { return sendToApp(new UserMsg(x)); });
			var title = __VirtualDom_doc.title;
			var bodyNode = __VirtualDom_doc.body;
			_VirtualDom_set_divertHrefToApp(divertHrefToApp);
			var currNode = __VirtualDom_virtualize(bodyNode);
			_VirtualDom_set_divertHrefToApp(0);
			var currBlocker = __Main_toBlockerType(initialModel);
			var currPopout;

			initialModel.popout.__sendToApp = sendToApp;

			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_set_divertHrefToApp(divertHrefToApp);
				var doc = view(__Main_getUserModel(model));
				var nextNode = __VirtualDom_node('body', new Empty,
					__Utils_ap(
						__List_map(doc.body, function(node) { return __VirtualDom_map(node, function(msg) { return new UserMsg(msg) }) }),
						new NonEmpty(__Main_cornerView(model), new Empty)
					)
				);
				var patches = __VirtualDom_diff(currNode, nextNode);
				bodyNode = __VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_set_divertHrefToApp(0);
				(title !== doc.title) && (__VirtualDom_doc.title = title = doc.title);

				// update blocker

				var nextBlocker = __Main_toBlockerType(model);
				_Debugger_updateBlocker(currBlocker, nextBlocker);
				currBlocker = nextBlocker;

				// view popout

				if (!model.popout.__doc) { currPopout = undefined; return; }

				_VirtualDom_set_doc(model.popout.__doc); // SWITCH TO POPOUT DOC
				currPopout || (currPopout = __VirtualDom_virtualize(model.popout.__doc.body));
				var nextPopout = __Main_popoutView(model);
				var popoutPatches = __VirtualDom_diff(currPopout, nextPopout);
				__VirtualDom_applyPatches(model.popout.__doc.body, currPopout, popoutPatches, sendToApp);
				currPopout = nextPopout;
				_VirtualDom_set_doc(document); // SWITCH BACK TO NORMAL DOC
			});
		}
	);
}};

function _Debugger_application(flagDecoder, init, view, update, subscriptions, onUrlRequest, onUrlChange, effectManagers)
{
	return _Browser_application(
		{
			documentFunction: _Debugger_document,
			flagDecoder: flagDecoder,
		},
		init,
		view,
		update,
		subscriptions,
		onUrlRequest,
		onUrlChange,
		effectManagers,
	);
}


function _Debugger_popout()
{
	return {
		__doc: undefined,
		__sendToApp: undefined
	};
}

function _Debugger_isOpen(popout)
{
	return !!popout.__doc;
}

function _Debugger_open(popout)
{
	return __Scheduler_binding(function(callback)
	{
		_Debugger_openWindow(popout);
		callback(__Scheduler_succeed(undefined));
	});
}

function _Debugger_openWindow(popout)
{
	var w = __Main_initialWindowWidth,
		h = __Main_initialWindowHeight,
	 	x = screen.width - w,
		y = screen.height - h;

	var debuggerWindow = window.open('', '', 'width=' + w + ',height=' + h + ',left=' + x + ',top=' + y);
	var doc = debuggerWindow.document;
	doc.title = 'Elm Debugger';

	// handle arrow keys
	doc.addEventListener('keydown', function(event) {
		event.metaKey && event.which === 82 && window.location.reload();
		event.key === 'ArrowUp'   && (popout.__sendToApp(new Up  ), event.preventDefault());
		event.key === 'ArrowDown' && (popout.__sendToApp(new Down), event.preventDefault());
	});

	// handle window close
	window.addEventListener('unload', close);
	debuggerWindow.addEventListener('unload', function() {
		popout.__doc = undefined;
		popout.__sendToApp(new NoOp);
		window.removeEventListener('unload', close);
	});

	function close() {
		popout.__doc = undefined;
		popout.__sendToApp(new NoOp);
		debuggerWindow.close();
	}

	// register new window
	popout.__doc = doc;
}



// SCROLL


function _Debugger_scroll(popout)
{
	// This is supposed to return a task.
	// But to avoid depending on the task manager, we execute the side effect function straight away instead.
	// return __Scheduler_binding(function(callback)
	// {
		if (popout.__doc)
		{
			var msgs = popout.__doc.getElementById('elm-debugger-sidebar');
			if (msgs && msgs.scrollTop !== 0)
			{
				msgs.scrollTop = 0;
			}
		}
	// 	callback(__Scheduler_succeed(undefined));
	// });
}


var _Debugger_scrollTo = function(id, popout)
{
	// This is supposed to return a task.
	// But to avoid depending on the task manager, we execute the side effect function straight away instead.
	// return __Scheduler_binding(function(callback)
	// {
		if (popout.__doc)
		{
			var msg = popout.__doc.getElementById(id);
			if (msg)
			{
				msg.scrollIntoView(false);
			}
		}
	// 	callback(__Scheduler_succeed(undefined));
	// });
};



// POPOUT CONTENT


function _Debugger_messageToString(value)
{
	if (value === undefined)
	{
		return 'Nil';
	}

	if (typeof value === 'boolean')
	{
		return value ? 'True' : 'False';
	}

	if (typeof value === 'number')
	{
		return value + '';
	}

	if (typeof value === 'string')
	{
		return '"' + _Debugger_addSlashes(value, false) + '"';
	}

	if (value instanceof String)
	{
		return "'" + _Debugger_addSlashes(value, true) + "'";
	}

	if (typeof value !== 'object' || value === null)
	{
		return '…';
	}

	if (Object.getPrototypeOf(value).constructor === Object)
	{
		return '…';
	}

	if (value instanceof ElmArray || value instanceof GleamSet || value instanceof Dict)
	{
		return '…';
	}

	var tag = Object.getPrototypeOf(value).constructor.name;
	var keys = Object.keys(value);
	switch (keys.length)
	{
		case 0:
			return tag;
		case 1:
			return tag + '(' + _Debugger_messageToString(value[keys[0]]) + ')';
		default:
			return tag + '(…, ' + _Debugger_messageToString(value[keys[keys.length - 1]]) + ')';
	}
}


function _Debugger_init(value)
{
	if (value === undefined)
	{
		return new Primitive('Nil');
	}

	if (value === null)
	{
		return new Primitive('null');
	}

	if (typeof value === 'boolean')
	{
		return new Constructor(new Some(value ? 'True' : 'False'), new Empty);
	}

	if (typeof value === 'number')
	{
		return new Primitive(value + '');
	}

	if (typeof value === 'string')
	{
		return new S('"' + _Debugger_addSlashes(value, false) + '"');
	}

	if (value instanceof String)
	{
		return new S("'" + _Debugger_addSlashes(value, true) + "'");
	}

	if (Array.isArray(value))
	{
		return new Constructor(new None, List.fromArray(value));
	}

	if (typeof value === 'object')
	{
		if (value instanceof List)
		{
			return new Sequence(new ListSeq, value);
		}

		if (value instanceof GleamSet)
		{
			return new Sequence(new SetSeq, Set_to_list(value));
		}

		if (value instanceof Dict)
		{
			return new Dictionary(Dict_to_list(value));
		}

		if (value instanceof ElmArray)
		{
			return new Sequence(new ArraySeq, Array_to_list(value));
		}

		if (Object.getPrototypeOf(value).constructor === Object)
		{
			return new Primitive('<internals>');
		}

		var name = Object.getPrototypeOf(value).constructor.name;
		if ('0' in value)
		{
			var list = [];
			for (var i in value)
			{
				list.push(value[i]);
			}
			return new Constructor(new Some(name), List.fromArray(list));
		}
		else
		{
			for (var i in value)
			{
				return new Record(name, Dict.fromObject(value));
			}
			return new Constructor(new Some(name), new Empty);
		}
	}

	return new Primitive('<internals>');
}

function _Debugger_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');
	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debugger_toUnexpanded(value)
{
	return value;
}



// BLOCK EVENTS


function _Debugger_updateBlocker(oldBlocker, newBlocker)
{
	if (oldBlocker === newBlocker) return;

	var oldEvents = _Debugger_blockerToEvents(oldBlocker);
	var newEvents = _Debugger_blockerToEvents(newBlocker);

	// remove old blockers
	for (var i = 0; i < oldEvents.length; i++)
	{
		document.removeEventListener(oldEvents[i], _Debugger_blocker, true);
	}

	// add new blockers
	for (var i = 0; i < newEvents.length; i++)
	{
		document.addEventListener(newEvents[i], _Debugger_blocker, true);
	}
}


function _Debugger_blocker(event)
{
	if (event.type === 'keydown' && event.metaKey && event.which === 82)
	{
		return;
	}

	var isScroll = event.type === 'scroll' || event.type === 'wheel';
	for (var node = event.target; node; node = node.parentNode)
	{
		if (isScroll ? node.id === 'elm-debugger-details' : node.id === 'elm-debugger-overlay')
		{
			return;
		}
	}

	event.stopPropagation();
	event.preventDefault();
}

function _Debugger_blockerToEvents(blocker)
{
	return blocker instanceof __Overlay_BlockNone
		? []
		: blocker instanceof __Overlay_BlockMost
			? _Debugger_mostEvents
			: _Debugger_allEvents;
}

var _Debugger_mostEvents = [
	'click', 'dblclick', 'mousemove',
	'mouseup', 'mousedown', 'mouseenter', 'mouseleave',
	'touchstart', 'touchend', 'touchcancel', 'touchmove',
	'pointerdown', 'pointerup', 'pointerover', 'pointerout',
	'pointerenter', 'pointerleave', 'pointermove', 'pointercancel',
	'dragstart', 'drag', 'dragend', 'dragenter', 'dragover', 'dragleave', 'drop',
	'keyup', 'keydown', 'keypress',
	'input', 'change',
	'focus', 'blur'
];

var _Debugger_allEvents = _Debugger_mostEvents.concat('wheel', 'scroll');

export {
	_Debugger_application,
	_Debugger_document,
	_Debugger_element,
	_Debugger_init,
	_Debugger_isOpen,
	_Debugger_messageToString,
	_Debugger_openWindow,
	_Debugger_scroll,
	_Debugger_scrollTo,
	_Debugger_toUnexpanded,
};
