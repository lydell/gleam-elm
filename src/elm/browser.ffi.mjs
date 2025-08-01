/*

import Basics exposing (never)
import Browser exposing (Internal, External)
import Browser.Dom as Dom exposing (NotFound)
import Elm.Kernel.Debug exposing (crash)
import Elm.Kernel.Debugger exposing (element, document)
import Elm.Kernel.Json exposing (runHelp)
import Elm.Kernel.List exposing (Nil)
import Elm.Kernel.Platform exposing (initialize)
import Elm.Kernel.Scheduler exposing (binding, fail, rawSpawn, succeed, spawn)
import Elm.Kernel.Utils exposing (Tuple0, Tuple2)
import Elm.Kernel.VirtualDom exposing (appendChild, applyPatches, diff, doc, node, passiveSupported, render, divertHrefToApp)
import Json.Decode as Json exposing (map)
import Maybe exposing (Just, Nothing)
import Result exposing (isOk)
import Task exposing (perform)
import Url exposing (fromString)

*/

import {
	Empty,
} from '../gleam.mjs';
import {
	never as __Basics_never,
} from './basics.mjs';
import {
	_Debug_crash as __Debug_crash,
} from './debug.ffi.mjs';
import {
	_Json_runHelp as __Json_runHelp,
} from './json.ffi.mjs';
import {
	_Platform_initialize as __Platform_initialize,
} from './platform.ffi.mjs';
import {
	_Scheduler_binding as __Scheduler_binding,
	_Scheduler_fail as __Scheduler_fail,
	_Scheduler_rawSpawn as __Scheduler_rawSpawn,
	_Scheduler_spawn as __Scheduler_spawn,
	_Scheduler_succeed as __Scheduler_succeed,
} from './scheduler.ffi.mjs';
import {
	perform as __Task_perform,
} from './task.mjs';
import {
	from_string as __Url_fromString,
} from './url.mjs';
import {
	_VirtualDom_applyPatches as __VirtualDom_applyPatches,
	_VirtualDom_diff as __VirtualDom_diff,
	_VirtualDom_doc as __VirtualDom_doc,
	_VirtualDom_node as __VirtualDom_node,
	_VirtualDom_passiveSupported as __VirtualDom_passiveSupported,
	_VirtualDom_set_divertHrefToApp,
	_VirtualDom_virtualize,
} from './virtual_dom.ffi.mjs';


// ELEMENT


var _Browser_element = function(flagDecoder, init, view, update, subscriptions, effectManagers) { return function(args)
{
	return __Platform_initialize(
		flagDecoder,
		args,
		init,
		update,
		subscriptions,
		effectManagers,
		function(sendToApp, initialModel) {
			/**__PROD*/
			var domNode = args['node'];
			//*/
			/**__DEBUG/
			var domNode = args && args['node'] ? args['node'] : __Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = __VirtualDom_diff(currNode, nextNode);
				domNode = __VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
}};



// DOCUMENT


var _Browser_document = function(flagDecoder, init, view, update, subscriptions, effectManagers) { return function(args)
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
		init,
		update,
		subscriptions,
		effectManagers,
		function(sendToApp, initialModel) {
			var divertHrefToApp = setup && setup(sendToApp)
			var title = __VirtualDom_doc.title;
			var bodyNode = __VirtualDom_doc.body;
			_VirtualDom_set_divertHrefToApp(divertHrefToApp);
			var currNode = _VirtualDom_virtualize(bodyNode);
			_VirtualDom_set_divertHrefToApp(0);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_set_divertHrefToApp(divertHrefToApp);
				var doc = view(model);
				var nextNode = __VirtualDom_node('body', new Empty, doc.body);
				var patches = __VirtualDom_diff(currNode, nextNode);
				bodyNode = __VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_set_divertHrefToApp(0);
				(title !== doc.title) && (__VirtualDom_doc.title = title = doc.title);
			});
		}
	);
}};



// ANIMATION


var _Browser_requestAnimationFrame_queue = {};
var _Browser_inAnimationFrame = false;
var _Browser_pendingAnimationFrame = false;
var _Browser_requestAnimationFrame_id = 0;

function _Browser_cancelAnimationFrame(id)
{
	delete _Browser_requestAnimationFrame_queue[id];
}

function _Browser_requestAnimationFrame(callback)
{
	var id = _Browser_requestAnimationFrame_id;
	_Browser_requestAnimationFrame_id++;
	_Browser_requestAnimationFrame_queue[id] = callback;
	if (!_Browser_pendingAnimationFrame)
	{
		_Browser_pendingAnimationFrame = true;
		_Browser_requestAnimationFrame_raw(function() {
			_Browser_pendingAnimationFrame = false;
			_Browser_inAnimationFrame = true;
			var maxId = _Browser_requestAnimationFrame_id;
			for (var id2 in _Browser_requestAnimationFrame_queue)
			{
				if (id2 >= maxId)
				{
					break;
				}
				var callback = _Browser_requestAnimationFrame_queue[id2];
				delete _Browser_requestAnimationFrame_queue[id2];
				callback();
			}
			_Browser_inAnimationFrame = false;
		});
	}
	return id;
}

var _Browser_requestAnimationFrame_raw =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };

function _Browser_makeAnimator(model, draw)
{
	// Whether `draw` is currently running. `draw` can cause side effects:
	// If the user renders a custom element, they can dispatch an event in
	// its `connectedCallback`, which happens synchronously. That causes
	// `update` to run while we’re in the middle of drawing, which then
	// causes another call to the returned function below. We can’t start
	// another draw while before the first one is finished.
	var drawing = false;

	// Whether we have already requested an animation frame for drawing.
	var pendingFrame = false;

	// Whether we have already requested to draw right after the current draw has finished.
	var pendingSync = false;

	function drawHelp()
	{
		// If we’re already drawing, wait until that draw is done.
		if (drawing)
		{
			pendingSync = true;
			return;
		}

		pendingFrame = false;
		pendingSync = false;
		drawing = true;
		draw(model);
		drawing = false;

		if (pendingSync)
		{
			drawHelp();
		}
	}

	function updateIfNeeded()
	{
		if (pendingFrame)
		{
			drawHelp();
		}
	}

	drawHelp();

	return function(nextModel, isSync)
	{
		model = nextModel;

		// When using `Browser.Events.onAnimationFrame` we already are
		// in an animation frame, so draw straight away. Otherwise we’ll
		// be drawing one frame late all the time.
		if (isSync || _Browser_inAnimationFrame)
		{
			drawHelp();
		}
		else if (!pendingFrame)
		{
			pendingFrame = true;
			_Browser_requestAnimationFrame(updateIfNeeded);
		}
	};
}



// APPLICATION


function _Browser_application(flagDecoder, init, view, update, subscriptions, onUrlRequest, onUrlChange, effectManagers)
{
	var documentFunction = _Browser_document;
	if (flagDecoder.documentFunction)
	{
		documentFunction = flagDecoder.documentFunction;
		flagDecoder = flagDecoder.flagDecoder;
	}

	var key = function() { key.__sendToApp(onUrlChange(_Browser_getUrl())); };

	return documentFunction(
		{
			setup: function(sendToApp)
			{
				key.__sendToApp = sendToApp;
				_Browser_window.addEventListener('popstate', key);
				_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

				return function(domNode) { return function(event)
				{
					if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download') && domNode.hasAttribute('href'))
					{
						event.preventDefault();
						var href = domNode.href;
						var curr = _Browser_getUrl();
						var next = __Url_fromString(href)[0];
						sendToApp(onUrlRequest(
							(next
								&& curr.protocol === next.protocol
								&& curr.host === next.host
								&& curr.port_[0] === next.port_[0]
							)
								? __Browser_Internal(next)
								: __Browser_External(href)
						));
					}
				}};
			},
			flagDecoder: flagDecoder,
		},
		function(flags)
		{
			return init(flags, _Browser_getUrl(), key);
		},
		view,
		update,
		subscriptions,
		effectManagers
	);
}

function _Browser_getUrl()
{
	return __Url_fromString(__VirtualDom_doc.location.href)[0] || __Debug_crash(1);
}

var _Browser_go = function(key, n)
{
	return __Task_perform(__Basics_never, __Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
};

var _Browser_pushUrl = function(key, url)
{
	return __Task_perform(__Basics_never, __Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
};

var _Browser_replaceUrl = function(key, url)
{
	return __Task_perform(__Basics_never, __Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
};



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_getDoc = function() { return _Browser_doc; };
var _Browser_getWindow = function() { return _Browser_window; };

var _Browser_on = function(node, eventName, sendToSelf)
{
	return __Scheduler_spawn(__Scheduler_binding(function(callback)
	{
		function handler(event)	{ __Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, __VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
};

var _Browser_decodeEvent = function(decoder, event)
{
	return __Json_runHelp(decoder, event);
};



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	var info = (typeof __VirtualDom_doc.hidden !== 'undefined')
		? { hidden: 'hidden', change: 'visibilitychange' }
		:
	(typeof __VirtualDom_doc.mozHidden !== 'undefined')
		? { hidden: 'mozHidden', change: 'mozvisibilitychange' }
		:
	(typeof __VirtualDom_doc.msHidden !== 'undefined')
		? { hidden: 'msHidden', change: 'msvisibilitychange' }
		:
	(typeof __VirtualDom_doc.webkitHidden !== 'undefined')
		? { hidden: 'webkitHidden', change: 'webkitvisibilitychange' }
		: { hidden: 'hidden', change: 'visibilitychange' };
	return [ info.hidden, info.change ];
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return __Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(__Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return __Scheduler_binding(function(callback)
	{
		callback(__Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return __Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? __Scheduler_succeed(doStuff(node))
				: __Scheduler_fail(__Dom_NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return __Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(__Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return undefined;
	});
};



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		scene: _Browser_getScene(),
		viewport: {
			x: _Browser_window.pageXOffset,
			y: _Browser_window.pageYOffset,
			width: _Browser_doc.documentElement.clientWidth,
			height: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		width: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		height: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return undefined;
	});
};



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			scene: {
				width: node.scrollWidth,
				height: node.scrollHeight
			},
			viewport: {
				x: node.scrollLeft,
				y: node.scrollTop,
				width: node.clientWidth,
				height: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return undefined;
	});
};



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			scene: _Browser_getScene(),
			viewport: {
				x: x,
				y: y,
				width: _Browser_doc.documentElement.clientWidth,
				height: _Browser_doc.documentElement.clientHeight
			},
			element: {
				x: x + rect.left,
				y: y + rect.top,
				width: rect.width,
				height: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return __Task_perform(__Basics_never, __Scheduler_binding(function(callback)
	{
		__VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return __Task_perform(__Basics_never, __Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			__VirtualDom_doc.location.reload(false);
		}
	}));
}

export {
	_Browser_application,
	_Browser_decodeEvent,
	_Browser_document,
	_Browser_element,
	_Browser_getDoc,
	_Browser_getWindow,
	_Browser_go,
	_Browser_load,
	_Browser_makeAnimator,
	_Browser_now,
	_Browser_on,
	_Browser_pushUrl,
	_Browser_rAF,
	_Browser_reload,
	_Browser_replaceUrl,
	_Browser_visibilityInfo,
};
