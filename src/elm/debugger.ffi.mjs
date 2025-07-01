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
import Set exposing (foldr)
import Dict exposing (foldr, empty, insert)
import Array exposing (foldr)

*/

import {
	Empty,
	NonEmpty,
} from '../gleam.mjs';
import {
	append as __Utils_ap,
	map as __List_map,
} from '../../gleam_stdlib/gleam/list.mjs';
import {
	_Browser_application,
	_Browser_makeAnimator,
} from './browser.ffi.mjs';
import {
	corner_view as __Main_cornerView,
	get_user_model as __Main_getUserModel,
	initial_window_height as __Main_initialWindowHeight,
	initial_window_width as __Main_initialWindowWidth,
	NoOp,
	popout_view as __Main_popoutView,
	to_blocker_type as __Main_toBlockerType,
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


// HELPERS


function _Debugger_unsafeCoerce(value)
{
	return value;
}



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
		event.key === 'ArrowUp'   && (popout.__sendToApp(__Main_Up  ), event.preventDefault());
		event.key === 'ArrowDown' && (popout.__sendToApp(__Main_Down), event.preventDefault());
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
	return __Scheduler_binding(function(callback)
	{
		if (popout.__doc)
		{
			var msgs = popout.__doc.getElementById('elm-debugger-sidebar');
			if (msgs && msgs.scrollTop !== 0)
			{
				msgs.scrollTop = 0;
			}
		}
		callback(__Scheduler_succeed(undefined));
	});
}


var _Debugger_scrollTo = function(id, popout)
{
	return __Scheduler_binding(function(callback)
	{
		if (popout.__doc)
		{
			var msg = popout.__doc.getElementById(id);
			if (msg)
			{
				msg.scrollIntoView(false);
			}
		}
		callback(__Scheduler_succeed(undefined));
	});
};



// UPLOAD


function _Debugger_upload(popout)
{
	return __Scheduler_binding(function(callback)
	{
		var doc = popout.__doc || document;
		var element = doc.createElement('input');
		element.setAttribute('type', 'file');
		element.setAttribute('accept', 'text/json');
		element.style.display = 'none';
		element.addEventListener('change', function(event)
		{
			var fileReader = new FileReader();
			fileReader.onload = function(e)
			{
				callback(__Scheduler_succeed(e.target.result));
			};
			fileReader.readAsText(event.target.files[0]);
			doc.body.removeChild(element);
		});
		doc.body.appendChild(element);
		element.click();
	});
}



// DOWNLOAD


var _Debugger_download = function(historyLength, json)
{
	return __Scheduler_binding(function(callback)
	{
		var fileName = 'history-' + historyLength + '.txt';
		var jsonString = JSON.stringify(json);
		var mime = 'text/plain;charset=utf-8';
		var done = __Scheduler_succeed(undefined);

		// for IE10+
		if (navigator.msSaveBlob)
		{
			navigator.msSaveBlob(new Blob([jsonString], {type: mime}), fileName);
			return callback(done);
		}

		// for HTML5
		var element = document.createElement('a');
		element.setAttribute('href', 'data:' + mime + ',' + encodeURIComponent(jsonString));
		element.setAttribute('download', fileName);
		element.style.display = 'none';
		document.body.appendChild(element);
		element.click();
		document.body.removeChild(element);
		callback(done);
	});
};



// POPOUT CONTENT


function _Debugger_messageToString(value)
{
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

	if (typeof value !== 'object' || value === null || !('$' in value))
	{
		return '…';
	}

	if (typeof value.$ === 'number')
	{
		return '…';
	}

	var code = value.$.charCodeAt(0);
	if (code === 0x23 /* # */ || /* a */ 0x61 <= code && code <= 0x7A /* z */)
	{
		return '…';
	}

	if (['Array_elm_builtin', 'Set_elm_builtin', 'RBNode_elm_builtin', 'RBEmpty_elm_builtin'].indexOf(value.$) >= 0)
	{
		return '…';
	}

	var keys = Object.keys(value);
	switch (keys.length)
	{
		case 1:
			return value.$;
		case 2:
			return value.$ + ' ' + _Debugger_messageToString(value.a);
		default:
			return value.$ + ' … ' + _Debugger_messageToString(value[keys[keys.length - 1]]);
	}
}


function _Debugger_init(value)
{
	if (typeof value === 'boolean')
	{
		return __Expando_Constructor(__Maybe_Just(value ? 'True' : 'False'), true, __List_Nil);
	}

	if (typeof value === 'number')
	{
		return __Expando_Primitive(value + '');
	}

	if (typeof value === 'string')
	{
		return __Expando_S('"' + _Debugger_addSlashes(value, false) + '"');
	}

	if (value instanceof String)
	{
		return __Expando_S("'" + _Debugger_addSlashes(value, true) + "'");
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (tag === '::' || tag === '[]')
		{
			return __Expando_Sequence(__Expando_ListSeq, true,
				__List_map(_Debugger_init, value)
			);
		}

		if (tag === 'Set_elm_builtin')
		{
			return __Expando_Sequence(__Expando_SetSeq, true,
				__Set_foldr(_Debugger_initCons, __List_Nil, value)
			);
		}

		if (tag === 'RBNode_elm_builtin' || tag == 'RBEmpty_elm_builtin')
		{
			return __Expando_Dictionary(true,
				__Dict_foldr(_Debugger_initKeyValueCons, __List_Nil, value)
			);
		}

		if (tag === 'Array_elm_builtin')
		{
			return __Expando_Sequence(__Expando_ArraySeq, true,
				__Array_foldr(_Debugger_initCons, __List_Nil, value)
			);
		}

		if (typeof tag === 'number')
		{
			return __Expando_Primitive('<internals>');
		}

		var char = tag.charCodeAt(0);
		if (char === 35 || 65 <= char && char <= 90)
		{
			var list = __List_Nil;
			for (var i in value)
			{
				if (i === '$') continue;
				list = __List_Cons(_Debugger_init(value[i]), list);
			}
			return __Expando_Constructor(char === 35 ? __Maybe_Nothing : __Maybe_Just(tag), true, __List_reverse(list));
		}

		return __Expando_Primitive('<internals>');
	}

	if (typeof value === 'object')
	{
		var dict = __Dict_empty;
		for (var i in value)
		{
			dict = __Dict_insert(i, _Debugger_init(value[i]), dict);
		}
		return __Expando_Record(true, dict);
	}

	return __Expando_Primitive('<internals>');
}

var _Debugger_initCons = function initConsHelp(value, list)
{
	return __List_Cons(_Debugger_init(value), list);
};

var _Debugger_initKeyValueCons = function(key, value, list)
{
	return __List_Cons(
		[_Debugger_init(key), _Debugger_init(value)],
		list
	);
};

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
	_Debugger_isOpen,
	_Debugger_open,
	_Debugger_scroll,
};
