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
	_Platform_initialize as __Platform_initialize,
} from '../core/platform.ffi.mjs';
import {
	_VirtualDom_applyPatches as __VirtualDom_applyPatches,
	_VirtualDom_diff as __VirtualDom_diff,
	_VirtualDom_doc as __VirtualDom_doc,
	_VirtualDom_node as __VirtualDom_node,
	_VirtualDom_passiveSupported as __VirtualDom_passiveSupported,
	_VirtualDom_set_divertHrefToApp,
	_VirtualDom_virtualize,
} from '../virtual_dom/virtual_dom.ffi.mjs';


// ELEMENT


var __Debugger_element;

var _Browser_element = __Debugger_element || function(impl) { return function(args)
{
	return __Platform_initialize(
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function(sendToApp, initialModel) {
			var view = impl.view;
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


var __Debugger_document;

var _Browser_document = __Debugger_document || function(impl) { return function(args)
{
	return __Platform_initialize(
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.setup && impl.setup(sendToApp)
			var view = impl.view;
			var title = __VirtualDom_doc.title;
			var bodyNode = __VirtualDom_doc.body;
			_VirtualDom_set_divertHrefToApp(divertHrefToApp);
			var currNode = _VirtualDom_virtualize(bodyNode);
			_VirtualDom_set_divertHrefToApp(0);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_set_divertHrefToApp(divertHrefToApp);
				var doc = view(model);
				var nextNode = __VirtualDom_node('body')(__List_Nil)(doc.body);
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

// Whether `draw` is currently running. `draw` can cause side effects:
// If the user renders a custom element, they can dispatch an event in
// its `connectedCallback`, which happens synchronously. That causes
// `update` to run while we’re in the middle of drawing, which then
// causes another call to the returned function below. We can’t start
// another draw while before the first one is finished.
// Another thing you can do in `connectedCallback`, is to initialize
// another Elm app. Even different app instances can conflict with each other,
// since they all use the same `_VirtualDom_renderCount` variable.
var _Browser_drawing = false;
var _Browser_drawSync_queue = [];

function _Browser_makeAnimator(model, draw)
{
	// Whether we have already requested an animation frame for drawing.
	var pendingFrame = false;

	// Whether we have already requested to draw right after the current draw has finished.
	var pendingSync = false;

	function drawHelp()
	{
		// If we’re already drawing, wait until that draw is done.
		if (_Browser_drawing)
		{
			if (!pendingSync)
			{
				pendingSync = true;
				_Browser_drawSync_queue.push(drawHelp);
			}
			return;
		}

		pendingFrame = false;
		pendingSync = false;
		_Browser_drawing = true;
		draw(model);
		_Browser_drawing = false;

		while (_Browser_drawSync_queue.length > 0)
		{
			var callback = _Browser_drawSync_queue.shift();
			callback();
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


function _Browser_application(impl)
{
	var onUrlChange = impl.onUrlChange;
	var onUrlRequest = impl.onUrlRequest;
	var key = function() { key.__sendToApp(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
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
					var next = __Url_fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.protocol === next.protocol
							&& curr.host === next.host
							&& curr.port_.a === next.port_.a
						)
							? __Browser_Internal(next)
							: __Browser_External(href)
					));
				}
			}};
		},
		init: function(flags)
		{
			return impl.init(flags, _Browser_getUrl(), key);
		},
		view: impl.view,
		update: impl.update,
		subscriptions: impl.subscriptions
	});
}

function _Browser_getUrl()
{
	return __Url_fromString(__VirtualDom_doc.location.href).a || __Debug_crash(1);
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
	var result = __Json_runHelp(decoder, event);
	return __Result_isOk(result) ? __Maybe_Just(result.a) : __Maybe_Nothing;
};



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof __VirtualDom_doc.hidden !== 'undefined')
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
		return __Utils_Tuple0;
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
		return __Utils_Tuple0;
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
		return __Utils_Tuple0;
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
	_Browser_element,
	_Browser_document,
	_Browser_application,
};
