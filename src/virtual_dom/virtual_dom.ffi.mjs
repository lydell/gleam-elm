/*

import Basics exposing (identity)
import Elm.Kernel.Debug exposing (crash)
import Elm.Kernel.Json exposing (runHelp, unwrap, wrap)
import Elm.Kernel.List exposing (Cons, Nil)
import Elm.Kernel.Utils exposing (Tuple2)
import Elm.Kernel.Platform exposing (export)
import Json.Decode as Json exposing (map, map2, succeed)
import Result exposing (isOk)
import VirtualDom exposing (toHandlerInt)

*/

import { F2, F3, F4, F5, F6, F7, F8, F9, A2, A3, A4, A5, A6, A7, A8, A9 } from '../elm.ffi.mjs';

var __2_TEXT = 0;
var __2_NODE = 1;
var __2_KEYED_NODE = 2;
var __2_CUSTOM = 3;
var __2_TAGGER = 4;
var __2_THUNK = 5;


// Double underscore sequences are replaced with single letters or numbers.
// Exactly which letter or number is used depends on the order the properties are first mentioned.
// This preserves the letters and numbers from v1.0.3 for compatibility with tools that assume those exact values.
// elm-explorations/test: https://github.com/elm-explorations/test/blob/d5eb84809de0f8bbf50303efd26889092c800609/src/Elm/Kernel/HtmlAsJson.js
// elm-pages: https://github.com/dillonkearns/elm-pages/blob/fa1d0347016e20917b412de5c3657c2e6e095087/generator/src/build.js#L642
// The list of names was extracted using the following commands:
// # Switch to the reference commit:
// git switch $old
// # Find all relevant double underscore tokens.
// grep --only --extended-regexp '_{2}[0-9a-z]\w+' src/Elm/Kernel/VirtualDom.js | awk '!visited[$0]++' >a.txt
// # Switch to the current commit:
// git switch $new
// # Exclude the below line, then find all relevant double underscore tokens.
// grep --invert-match void src/Elm/Kernel/VirtualDom.js | grep --only --extended-regexp '_{2}[0-9a-z]\w+' | awk '!visited[$0]++' >b.txt
// # Keep only the double underscore tokens from the reference commit that still exist.
// grep --fixed-strings --line-regexp --file=b.txt a.txt
void { __2_TEXT: null, __text: null, __descendantsCount: null, __2_NODE: null, __tag: null, __facts: null, __kids: null, __namespace: null, __2_KEYED_NODE: null, __2_CUSTOM: null, __model: null, __render: null, __diff: null, __2_TAGGER: null, __tagger: null, __node: null, __2_THUNK: null, __refs: null, __thunk: null, __1_EVENT: null, __key: null, __value: null, __1_STYLE: null, __1_PROP: null, __1_ATTR: null, __1_ATTR_NS: null, __handler: null, __eventNode: null };


// HELPERS


// Increases by 1 before every render. Used to know if the DOM node index
// on each virtual node needs to be reset.
// Even if you render 10 000 times per second, this counter won't become
// too big until after 25 000 years.
var _VirtualDom_renderCount = 0;

var _VirtualDom_everTranslated = false;

var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

function _VirtualDom_insertBefore(parent, child, reference)
{
	if (!(child.parentNode === parent && child.nextSibling === reference))
	{
		parent.insertBefore(child, reference);
	}
}

function _VirtualDom_insertAfter(parent, child, reference)
{
	if (!(child.parentNode === parent && child.previousSibling === reference))
	{
		parent.insertBefore(child, reference === null ? parent.firstChild : reference.nextSibling);
	}
}

function _VirtualDom_moveBefore_(parent, child, reference)
{
	if (!(child.parentNode === parent && child.nextSibling === reference))
	{
		parent.moveBefore(child, reference);
	}
}

function _VirtualDom_moveAfter_(parent, child, reference)
{
	if (!(child.parentNode === parent && child.previousSibling === reference))
	{
		parent.moveBefore(child, reference === null ? parent.firstChild : reference.nextSibling);
	}
}

var _VirtualDom_supports_moveBefore = typeof Element !== 'undefined' && typeof Element.prototype.moveBefore === 'function';

var _VirtualDom_moveBefore = _VirtualDom_supports_moveBefore ? _VirtualDom_moveBefore_ : _VirtualDom_insertBefore;

var _VirtualDom_moveAfter = _VirtualDom_supports_moveBefore ? _VirtualDom_moveAfter_ : _VirtualDom_insertAfter;

var _VirtualDom_init = F2(function(virtualNode, args)
{
	// NOTE: this function needs __Platform_export available to work

	/**__PROD*/
	var node = args['node'];
	//*/
	/**__DEBUG/
	var node = args && args['node'] ? args['node'] : __Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: __2_TEXT,
		__text: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		return {
			$: __2_NODE,
			__tag: tag,
			__facts: _VirtualDom_organizeFacts(factList),
			__kids: kidList.toArray(),
			__namespace: namespace,
			// Unused, only exists for backwards compatibility with:
			// https://github.com/elm-explorations/test/blob/9669a27d84fc29175364c7a60d5d700771a2801e/src/Test/Html/Internal/ElmHtml/InternalTypes.elm#L279
			// https://github.com/dillonkearns/elm-pages/blob/fa1d0347016e20917b412de5c3657c2e6e095087/src/Test/Html/Internal/ElmHtml/InternalTypes.elm#L281
			__descendantsCount: 0
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], kidsMap = Object.create(null); kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			var key = kid.a;
			// Handle duplicate keys by adding a postfix.
			while (key in kidsMap)
			{
				key += _VirtualDom_POSTFIX;
			}
			kids.push(kid);
			kidsMap[key] = kid.b;
		}

		return {
			$: __2_KEYED_NODE,
			__tag: tag,
			__facts: _VirtualDom_organizeFacts(factList),
			// __kids holds the order and length of the kids.
			__kids: kids,
			// __kidsMap is a dict from key to node.
			// Note when iterating JavaScript objects, numeric-looking keys come first.
			// So we need both __kids and __kidsMap.
			// Another reason is backwards compatibility with:
			// https://github.com/elm-explorations/test/blob/d5eb84809de0f8bbf50303efd26889092c800609/src/Elm/Kernel/HtmlAsJson.js#L37
			// https://github.com/dillonkearns/elm-pages/blob/fa1d0347016e20917b412de5c3657c2e6e095087/generator/src/build.js#L675
			__kidsMap: kidsMap,
			__namespace: namespace,
			__descendantsCount: 0 // See _VirtualDom_nodeNS.
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: __2_CUSTOM,
		__facts: _VirtualDom_organizeFacts(factList),
		__model: model,
		__render: render,
		__diff: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: __2_TAGGER,
		__tagger: tagger,
		__node: node,
		__descendantsCount: 0 // See _VirtualDom_nodeNS.
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: __2_THUNK,
		__refs: refs,
		__thunk: thunk,
		__node: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a__1_EVENT',
		__key: key,
		__value: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a__1_STYLE',
		__key: key,
		__value: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a__1_PROP',
		__key: key,
		__value: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a__1_ATTR',
		__key: key,
		__value: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a__1_ATTR_NS',
		__key: key,
		__value: { __namespace: namespace, __value: value }
	};
});



// XSS ATTACK VECTOR CHECKS
//
// For some reason, tabs can appear in href protocols and it still works.
// So '\tjava\tSCRIPT:alert("!!!")' and 'javascript:alert("!!!")' are the same
// in practice. That is why _VirtualDom_RE_js and _VirtualDom_RE_js_html look
// so freaky.
//
// Pulling the regular expressions out to the top level gives a slight speed
// boost in small benchmarks (4-10%) but hoisting values to reduce allocation
// can be unpredictable in large programs where JIT may have a harder time with
// functions are not fully self-contained. The benefit is more that the js and
// js_html ones are so weird that I prefer to see them near each other.


var _VirtualDom_RE_script = /^script$/i;
var _VirtualDom_RE_on_formAction = /^(on|formAction$)/i;
var _VirtualDom_RE_js = /^\s*j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i;
var _VirtualDom_RE_js_html = /^\s*(j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:|d\s*a\s*t\s*a\s*:\s*t\s*e\s*x\s*t\s*\/\s*h\s*t\s*m\s*l\s*(,|;))/i;


function _VirtualDom_noScript(tag)
{
	return _VirtualDom_RE_script.test(tag) ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return _VirtualDom_RE_on_formAction.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return _VirtualDom_RE_js.test(value)
		? /**__PROD/''//*//**__DEBUG*/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return _VirtualDom_RE_js_html.test(value)
		? /**__PROD/''//*//**__DEBUG*/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlJson(value)
{
	return (typeof __Json_unwrap(value) === 'string' && _VirtualDom_RE_js_html.test(__Json_unwrap(value)))
		? __Json_wrap(
			/**__PROD/''//*//**__DEBUG/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		) : value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a__1_EVENT')
		? A2(_VirtualDom_on, attr.__key, _VirtualDom_mapHandler(func, attr.__value))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = __VirtualDom_toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2(__Json_map, func, handler.a)
				:
			A3(__Json_map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				__Json_succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return __Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		__$message: func(record.__$message),
		__$stopPropagation: record.__$stopPropagation,
		__$preventDefault: record.__$preventDefault
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	var facts = {};

	// Mark all elements for virtualization of server rendered nodes – see `_VirtualDom_markerProperty`.
	facts[_VirtualDom_markerProperty] = true;

	for (var entry of factList) // WHILE_CONS
	{
		var tag = entry.$;
		var key = entry.__key;
		var value = entry.__value;

		if (tag === 'a__1_PROP')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, __Json_unwrap(value))
				: facts[key] = __Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a__1_ATTR' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === __2_THUNK)
	{
		return _VirtualDom_render(vNode.__node || (vNode.__node = vNode.__thunk()), eventNode);
	}

	if (tag === __2_TAGGER)
	{
		return _VirtualDom_render(vNode.__node, function (msg) { return eventNode(vNode.__tagger(msg)) });
	}

	if (tag === __2_TEXT)
	{
		var domNode = _VirtualDom_doc.createTextNode(vNode.__text);
		_VirtualDom_storeDomNode(vNode, domNode)
		return domNode;
	}

	if (tag === __2_CUSTOM)
	{
		var domNode = vNode.__render(vNode.__model);
		_VirtualDom_applyFacts(domNode, eventNode, {}, vNode.__facts);
		_VirtualDom_storeDomNode(vNode, domNode);
		return domNode;
	}

	// at this point `tag` must be __2_NODE or __2_KEYED_NODE

	var domNode = vNode.__namespace
		? _VirtualDom_doc.createElementNS(vNode.__namespace, vNode.__tag)
		: _VirtualDom_doc.createElement(vNode.__tag);

	if (_VirtualDom_divertHrefToApp && vNode.__tag == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, {}, vNode.__facts);

	for (var kids = vNode.__kids, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === __2_NODE ? kids[i] : kids[i].b, eventNode));
	}

	_VirtualDom_storeDomNode(vNode, domNode);

	return domNode;
}

// Like `_VirtualDom_render`, but:
// - Assumes that we have already gone through diffing.
// - Only re-renders text nodes.
function _VirtualDom_renderTranslated(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === __2_THUNK)
	{
		return _VirtualDom_renderTranslated(vNode.__node, eventNode);
	}

	if (tag === __2_TAGGER)
	{
		return _VirtualDom_renderTranslated(vNode.__node, function (msg) { return eventNode(vNode.__tagger(msg)) });
	}

	var newDomNodes = vNode[_VirtualDom_instance].__newDomNodes;

	if (tag === __2_TEXT)
	{
		var newNode = _VirtualDom_doc.createTextNode(vNode.__text);
		newDomNodes[newDomNodes.length - 1] = newNode;
		return newNode;
	}

	return newDomNodes[newDomNodes.length - 1];
}

function _VirtualDom_storeDomNode(vNode, domNode)
{
	_VirtualDom_wrap(vNode);
	var vNode_ = vNode[_VirtualDom_instance];
	if (vNode_.__renderedAt !== _VirtualDom_renderCount)
	{
		vNode_.__oldDomNodes = vNode_.__newDomNodes;
		vNode_.__newDomNodes = [];
		vNode_.__i = 0;
		vNode_.__renderedAt = _VirtualDom_renderCount;
	}
	vNode_.__newDomNodes.push(domNode);
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, prevFacts, facts)
{
	// Since properties and attributes are sometimes linked, we need to remove old
	// ones before setting new ones. Otherwise we might set the `id` attribute and
	// then remove the `id` property, resulting in no id, for example.

	if (prevFacts.a__1_STYLE !== undefined)
	{
		_VirtualDom_removeStyles(domNode, prevFacts.a__1_STYLE, facts.a__1_STYLE || {});
	}

	// `_VirtualDom_organizeFacts` puts properties directly on the `facts` object,
	// instead of at `facts.a__1_PROP` which would have been more reasonable. So
	// we pass the entire `facts` as the props, and `_VirtualDom_removeProps` needs
	// to ignore `a__1_ATTR` etc.
	// This results in that you can mess things up by setting properties called "a0" to "a4",
	// but it’s not a big deal.
	// We can’t fix this because of backwards compatibility with:
	// https://github.com/elm-explorations/test/blob/9669a27d84fc29175364c7a60d5d700771a2801e/src/Test/Html/Internal/ElmHtml/InternalTypes.elm#L328
	// https://github.com/dillonkearns/elm-pages/blob/fa1d0347016e20917b412de5c3657c2e6e095087/src/Test/Html/Internal/ElmHtml/InternalTypes.elm#L330
	_VirtualDom_removeProps(domNode, prevFacts, facts);

	if (prevFacts.a__1_ATTR !== undefined)
	{
		_VirtualDom_removeAttrs(domNode, prevFacts.a__1_ATTR, facts.a__1_ATTR || {});
	}

	if (prevFacts.a__1_ATTR_NS !== undefined)
	{
		_VirtualDom_removeAttrsNS(domNode, prevFacts.a__1_ATTR_NS, facts.a__1_ATTR_NS || {});
	}

	// Then, apply new facts.

	if (facts.a__1_STYLE !== undefined)
	{
		_VirtualDom_applyStyles(domNode, prevFacts.a__1_STYLE || {}, facts.a__1_STYLE);
	}

	if (facts.a__1_ATTR !== undefined)
	{
		_VirtualDom_applyAttrs(domNode, prevFacts.a__1_ATTR || {}, facts.a__1_ATTR);
	}

	if (facts.a__1_ATTR_NS !== undefined)
	{
		_VirtualDom_applyAttrsNS(domNode, prevFacts.a__1_ATTR_NS || {}, facts.a__1_ATTR_NS);
	}

	// Apply properties _after_ attributes. This means that if you set the same thing both as a property and an attribute,
	// the property wins. If the attribute had won, the property would “win” during the next render, since properties are
	// diffed against the actual DOM node, while attributes are diffed against the previous virtual node. So it's better
	// to let the property win right away.
	// See the comment at the `_VirtualDom_removeProps` call earlier in this function for why we pass the entire `facts` object.
	_VirtualDom_applyProps(domNode, facts);

	// Finally, apply events. There is no separate phase for removing events.
	// Attributes and properties can't interfere with events, so it's fine.

	if (facts.a__1_EVENT !== undefined || prevFacts.a__1_EVENT !== undefined)
	{
		_VirtualDom_applyEvents(domNode, eventNode, facts.a__1_EVENT || {});
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, prevStyles, styles)
{
	for (var key in styles)
	{
		var value = styles[key];
		if (value !== prevStyles[key])
		{
			// `.setProperty` must be used for `--custom-properties`.
			// Standard properties never start with a dash.
			// `.setProperty` requires for example 'border-radius' with a dash,
			// while both `.style['border-radius']` and `.style['borderRadius']` work.
			// Elm used to only use `.style`. In order to support existing code like
			// `Html.Attributes.style 'borderRadius' '5px'` we default to `.style`
			// and only use `.setProperty` if the property name starts with a dash.
			if (key.charCodeAt(0) === 45)
			{
				domNode.style.setProperty(key, value);
			}
			else
			{
				domNode.style[key] = value;
			}
		}
	}
}


function _VirtualDom_removeStyles(domNode, prevStyles, styles)
{
	for (var key in prevStyles)
	{
		if (!(key in styles))
		{
			// See `_VirtualDom_applyStyles`.
			if (key.charCodeAt(0) === 45)
			{
				domNode.style.removeProperty(key);
			}
			else
			{
				domNode.style[key] = '';
			}
		}
	}
}



// APPLY PROPS

function _VirtualDom_applyProps(domNode, props)
{
	for (var key in props)
	{
		// See `_VirtualDom_applyFacts` and `_VirtualDom_markerProperty` for why we need to filter these.
		if (key === 'a__1_EVENT' || key === 'a__1_STYLE' || key === 'a__1_ATTR' || key === 'a__1_ATTR_NS' || key === _VirtualDom_markerProperty)
		{
			continue;
		}

		var value = props[key];
		// `value`, `checked`, `selected` and `selectedIndex` can all change via
		// user interactions, so for those it’s important to compare to the
		// actual DOM value. Because of that we compare against the actual DOM
		// node, rather than `prevProps`. Note that many properties are
		// normalized (to certain values, or to a full URL, for example), so if
		// you use properties they might be set on every render if you don't
		// supply the normalized form. `Html.Attributes` avoids this by
		// primarily using attributes.
		if (value !== domNode[key])
		{
			domNode[key] = value;
		}
	}
}


function _VirtualDom_removeProps(domNode, prevProps, props)
{
	for (var key in prevProps)
	{
		// See `_VirtualDom_applyFacts` and `_VirtualDom_markerProperty` for why we need to filter these.
		if (key === 'a__1_EVENT' || key === 'a__1_STYLE' || key === 'a__1_ATTR' || key === 'a__1_ATTR_NS' || key === _VirtualDom_markerProperty)
		{
			continue;
		}

		if (!(key in props))
		{
			var value = props[key];
			switch (typeof value)
			{
				// Most string properties default to the empty string.
				case 'string':
					domNode[key] = '';
					break;
				// Most boolean properties default to false.
				case 'boolean':
					domNode[key] = false;
					break;
				// For other types it's unclear what to do.
			}
			// Standard properties cannot be deleted, but it is not an error trying.
			// Non-standard properties can be deleted.
			delete domNode[key];
		}
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, prevAttrs, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		if (value !== prevAttrs[key])
		{
			domNode.setAttribute(key, value);
		}
	}
}


function _VirtualDom_removeAttrs(domNode, prevAttrs, attrs)
{
	for (var key in prevAttrs)
	{
		if (!(key in attrs))
		{
			domNode.removeAttribute(key);
		}
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, prevNsAttrs, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.__namespace;
		var value = pair.__value;
		var previous = prevNsAttrs[key];
		if (!previous)
		{
			domNode.setAttributeNS(namespace, key, value);
		}
		else if (previous.__namespace !== namespace)
		{
			domNode.removeAttributeNS(previous.__namespace, key);
			domNode.setAttributeNS(namespace, key, value);
		}
		else if (previous.__value !== value)
		{
			domNode.setAttributeNS(namespace, key, value);
		}
	}
}


function _VirtualDom_removeAttrsNS(domNode, prevNsAttrs, nsAttrs)
{
	for (var key in prevNsAttrs)
	{
		if (!(key in nsAttrs))
		{
			domNode.removeAttributeNS(prevNsAttrs[key].__namespace, key);
		}
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			delete allCallbacks[key];
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.__handler;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.__handler = newHandler;
				oldCallback.__eventNode = eventNode;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: __VirtualDom_toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}

	for (key in allCallbacks)
	{
		if (!(key in events))
		{
			domNode.removeEventListener(key, allCallbacks[key]);
			delete allCallbacks[key];
		}
	}
}

function _VirtualDom_lazyUpdateEvents(domNode, eventNode)
{
	var allCallbacks = domNode.elmFs;

	if (allCallbacks)
	{
		for (var key in allCallbacks)
		{
			var oldCallback = allCallbacks[key];
			oldCallback.__eventNode = eventNode;
		}
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(initialEventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.__handler;
		var eventNode = callback.__eventNode;
		var result = __Json_runHelp(handler.a, event);

		if (!__Result_isOk(result))
		{
			return;
		}

		var tag = __VirtualDom_toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.__$message;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.__$stopPropagation;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.__$preventDefault) && event.preventDefault(),
			eventNode
		);
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.__handler = initialHandler;
	callback.__eventNode = initialEventNode;

	return callback;
}



// DIFF


function _VirtualDom_diff(_x, y)
{
	// Hack to provide the new virtual dom node to `_VirtualDom_applyPatches` without
	// making breaking changes to elm/browser.
	return y;
}

function _VirtualDom_diffHelp(x, y, eventNode)
{
	if (x === y)
	{
		return {
			__domNode: _VirtualDom_quickVisit(x, y, eventNode),
			__translated: false,
			__reinsert: false
		};
	}

	// Remember: When virtualizing already existing DOM, we can’t know
	// where `map` and `lazy` nodes should be, and which ones are `Keyed`.
	// So it’s important to not redraw fully when just the new virtual dom node
	// is a `map` or `lazy` or `Keyed`, to avoid unnecessary DOM changes on startup.

	while (x.$ === __2_TAGGER)
	{
		x = x.__node;
	}

	if (y.$ === __2_TAGGER)
	{
		return _VirtualDom_diffHelp(x, y.__node, function (msg) { return eventNode(y.__tagger(msg)) });
	}

	if (x.$ === __2_THUNK)
	{
		if (y.$ === __2_THUNK)
		{
			var xRefs = x.__refs;
			var yRefs = y.__refs;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.__node = x.__node;
				// We still need to visit every node inside the lazy node, to
				// make sure that the event listeners get the current
				// `eventNode`, and to increase and reset counters. This is
				// cheaper than calling `view`, diffing and rendering at least.
				return {
					__domNode: _VirtualDom_quickVisit(x, y, eventNode),
					__translated: false,
					__reinsert: false
				};
			}
			y.__node = y.__thunk();
			return _VirtualDom_diffHelp(x.__node, y.__node, eventNode);
		}
		else
		{
			return _VirtualDom_diffHelp(x.__node, y, eventNode);
		}
	}

	if (y.$ === __2_THUNK)
	{
		return _VirtualDom_diffHelp(x, y.__node || (y.__node = y.__thunk()), eventNode);
	}

	var domNode = _VirtualDom_consumeDomNode(x, y);

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === __2_NODE && yType === __2_KEYED_NODE)
		{
			y = _VirtualDom_dekey(y);
			yType = __2_NODE;
		}
		else if (xType === __2_KEYED_NODE && yType === __2_NODE)
		{
			x = _VirtualDom_dekey(x);
			xType = __2_NODE;
		}
		else
		{
			return _VirtualDom_applyPatchRedraw(x, y, eventNode);
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case __2_TEXT:
			if (x.__text !== y.__text)
			{
				// Text replaced or changed by translation plugins.
				if (!domNode.parentNode || domNode.data !== x.__text)
				{
					return {
						__domNode: domNode,
						__translated: true,
						__reinsert: false
					};
				}
				// Google Translate has a race condition-style bug where if you update the text
				// of a text node while it is fetching a translation for it, you’ll end up with
				// that out-of-date translation. So if we’ve ever detected a translation, it’s
				// no longer safe to update text nodes. Instead, we must replace them with new ones.
				// That’s slower, so we only switch to this method if needed.
				// See: https://issues.chromium.org/issues/393698470
				if (_VirtualDom_everTranslated)
				{
					var newNode = _VirtualDom_doc.createTextNode(y.__text);
					y[_VirtualDom_instance].__newDomNodes[y[_VirtualDom_instance].__newDomNodes.length - 1] = newNode;
					domNode.parentNode.replaceChild(newNode, domNode);
					domNode = newNode;
				}
				else
				{
					domNode.data = y.__text;
				}
			}
			return {
				__domNode: domNode,
				__translated: false,
				__reinsert: false
			};

		case __2_NODE:
			return _VirtualDom_diffNodes(domNode, x, y, eventNode, _VirtualDom_diffKids);

		case __2_KEYED_NODE:
			return _VirtualDom_diffNodes(domNode, x, y, eventNode, _VirtualDom_diffKeyedKids);

		case __2_CUSTOM:
			if (x.__render !== y.__render)
			{
				return _VirtualDom_applyPatchRedraw(x, y, eventNode);
			}

			_VirtualDom_applyFacts(domNode, eventNode, x.__facts, y.__facts);

			var patch = y.__diff(x.__model, y.__model);
			patch && patch(domNode);

			return {
				__domNode: domNode,
				__translated: false,
				__reinsert: false
			};
	}
}

// When we know that a node does not need updating, just quickly visit its children to:
// - Make sure that properties match the virtual node – they can be mutated by user actions, such as typing into an input.
//   `Html.Attributes` primarily uses attributes (not properties), so this shouldn’t take much time.
// - Update event listeners’ reference to the current `eventNode`.
// - Increase or reset `.__i`.
function _VirtualDom_quickVisit(x, y, eventNode)
{
	switch (y.$)
	{
		case __2_TAGGER:
			return _VirtualDom_quickVisit(x.__node, y.__node, function (msg) { return eventNode(y.__tagger(msg)) });

		case __2_THUNK:
			return _VirtualDom_quickVisit(x.__node, y.__node, eventNode);
	}

	var domNode = _VirtualDom_consumeDomNode(x, y);

	switch (y.$)
	{
		case __2_TEXT:
			return domNode;

		case __2_NODE:
			_VirtualDom_applyProps(domNode, y.__facts);
			_VirtualDom_lazyUpdateEvents(domNode, eventNode);
			for (var xKids = x.__kids, yKids = y.__kids, i = 0; i < yKids.length; i++)
			{
				_VirtualDom_quickVisit(xKids[i], yKids[i], eventNode);
			}
			return domNode;

		case __2_KEYED_NODE:
			_VirtualDom_applyProps(domNode, y.__facts);
			_VirtualDom_lazyUpdateEvents(domNode, eventNode);
			for (var xKids = x.__kids, yKids = y.__kids, i = 0; i < yKids.length; i++)
			{
				_VirtualDom_quickVisit(xKids[i].b, yKids[i].b, eventNode);
			}
			return domNode;

		case __2_CUSTOM:
			_VirtualDom_applyProps(domNode, y.__facts);
			_VirtualDom_lazyUpdateEvents(domNode, eventNode);
			return domNode;
	}
}

// When we remove a node, quickly visit its children to remove dom nodes from the virtual nodes.
function _VirtualDom_removeVisit(x, shouldRemoveFromDom)
{
	switch (x.$)
	{
		case __2_TAGGER:
			_VirtualDom_removeVisit(x.__node, shouldRemoveFromDom);
			return;

		case __2_THUNK:
			_VirtualDom_removeVisit(x.__node, shouldRemoveFromDom);
			return;
	}

	var domNode;
	var x_ = x[_VirtualDom_instance];

	if (x_.__renderedAt === _VirtualDom_renderCount)
	{
		domNode = x_.__oldDomNodes[x_.__i];
		x_.__i++;
		// When the last DOM node for a constant like `none = Html.text ""` is removed,
		// clear the old DOM nodes so that we don’t hold on to them in memory (in case
		// the constant is never used again – the old DOM nodes are only cleared on the
		// next render normally). Note that if the constant drops from 1000 usages to 1,
		// the condition below might not be true, and we’ll hold on to the 999 extra DOM
		// nodes until the next render. Another render is quite likely to happen, though.
		if (x_.__i >= x_.__oldDomNodes.length)
		{
			x_.__oldDomNodes.length = 0;
			x_.__i = 0;
		}
	}
	else
	{
		domNode = x_.__newDomNodes[0]; // Read from the to-be `oldDomNodes` (see below).
		// This is again for constants like `none = Html.text ""`. The `if` statement
		// about that above would work _after_ the whole `renderedAt` if-else block,
		// but it’s very common to have just one DOM node per virtual node, so doing
		// the check in both `if` and `else` lets us optimize a little bit by avoiding
		// assigning properties twice.
		if (x_.__newDomNodes.length === 1)
		{
			x_.__oldDomNodes = [];
			x_.__i = 0;
		}
		else
		{
			x_.__oldDomNodes = x_.__newDomNodes;
			x_.__i = 1;
		}
		x_.__newDomNodes = [];
		x_.__renderedAt = _VirtualDom_renderCount;
	}
	if (shouldRemoveFromDom) {
		// An extension might have (re-)moved the element, so we can’t just
		// call `parentDomNode.removeChild(domNode)`. That throws an error if
		// the node is not a child of `parentDomNode`.
		var parentNode = domNode.parentNode;
		if (parentNode)
		{
			parentNode.removeChild(domNode);
		}
	}

	switch (x.$)
	{
		case __2_TEXT:
			return;

		case __2_NODE:
			for (var kids = x.__kids, i = 0; i < kids.length; i++)
			{
				_VirtualDom_removeVisit(kids[i], false);
			}
			return;

		case __2_KEYED_NODE:
			for (var kids = x.__kids, i = 0; i < kids.length; i++)
			{
				_VirtualDom_removeVisit(kids[i].b, false);
			}
			return;

		case __2_CUSTOM:
			return;
	}
}

// Consume DOM node number `__i` from `x`:s "old" nodes,
// push it to `y`:s "new" nodes, and return the DOM node.
// Reset things if from a different render.
// Note: Since the exact same virtual DOM node can be used more than once,
// we can’t think of `x` as the “old” one and `y` as the “new” one.
// Both `x` and `y` need to have _all_ the `[_VirtualDom_foo].` fields reset when
// the render count changes.
function _VirtualDom_consumeDomNode(x, y)
{
	_VirtualDom_wrap(y);
	var x_ = x[_VirtualDom_instance];
	var y_ = y[_VirtualDom_instance];
	if (y_.__renderedAt !== _VirtualDom_renderCount)
	{
		y_.__oldDomNodes = y_.__newDomNodes;
		y_.__newDomNodes = [];
		y_.__i = 0;
		y_.__renderedAt = _VirtualDom_renderCount;
	}
	if (x_.__renderedAt === _VirtualDom_renderCount)
	{
		var domNode = x_.__oldDomNodes[x_.__i];
		y_.__newDomNodes.push(domNode);
		x_.__i++;
		return domNode;
	}
	else
	{
		x_.__oldDomNodes = x_.__newDomNodes;
		x_.__newDomNodes = [];
		var domNode = x_.__oldDomNodes[0];
		y_.__newDomNodes.push(domNode);
		x_.__i = 1;
		x_.__renderedAt = _VirtualDom_renderCount;
		return domNode;
	}
}

function _VirtualDom_diffNodes(domNode, x, y, eventNode, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.__tag !== y.__tag || x.__namespace !== y.__namespace)
	{
		return _VirtualDom_applyPatchRedraw(x, y, eventNode);
	}

	_VirtualDom_applyFacts(domNode, eventNode, x.__facts, y.__facts);

	var translated = diffKids(domNode, x, y, eventNode);

	// If at least one kid was detected to have been translated (by Google Translate for example),
	// we need to go through all kids and actual DOM node children once more. If a text node
	// has been replaced by another with translated text, we don’t know _which_ text node it has
	// been replace by. We have to rerender _all_ text inside the element. This has the side benefit
	// of increasing the likelihood of getting a well-formed sentence after the translator re-translates
	// the text. Since different languages have different word order, it’s the best to translate
	// whole sentences at the minimum. It’s difficult to heuristically find a sentence or paragraph
	// though. “All the text directly inside this element” is the best we’ve got so far.
	if (translated)
	{
		_VirtualDom_everTranslated = true;

		for (var current = null, kids = y.__kids, i = kids.length - 1, j = domNode.childNodes.length - 1; i >= 0; i--)
		{
			var kid = kids[i];
			var vNode = y.$ === __2_KEYED_NODE ? kid.b : kid;

			// `child` is going to be one of:
			// - For text nodes: A new text node that isn’t inserted into the DOM.
			// - For other nodes: The already existing DOM node. An extension
			//   might have removed it, though, or moved it to another parent.
			var child = _VirtualDom_renderTranslated(vNode, eventNode);

			if (child.parentNode === domNode)
			{
				// Go through the actual children of `domNode` until we hit `child`,
				// which we just checked for sure is a child of `domNode`. We know
				// that all “our” kids are in the correct order.
				for (; j >= 0; j--)
				{
					current = domNode.childNodes[j];
					if (current === child)
					{
						j--;
						break;
					}
					// Any element we come across until we find `child` must be created by others,
					// or be text nodes created by us but abandoned in `_VirtualDom_renderTranslated`.
					// Remove all text nodes, and all font tags (most likely created by Google Translate).
					if (current.nodeType === 3 || current.localName === 'font')
					{
						domNode.removeChild(current);
					}
				}
			}
			else
			{
				// Most likely, we are inserting a new text node here.
				// It could also be an element (re-)moved by an extension.
				_VirtualDom_insertBefore(domNode, child, current);
				current = domNode;
			}
		}

		// If there are more elements before our first kid, go through them as well like above.
		for (; j >= 0; j--)
		{
			current = domNode.childNodes[j];
			if (child.nodeType === 3 || current.localName === 'font')
			{
				domNode.removeChild(current);
			}
		}
	}

	return {
		__domNode: domNode,
		__translated: false,
		__reinsert: false
	};
}



// DIFF KIDS


function _VirtualDom_diffKids(parentDomNode, xParent, yParent, eventNode)
{
	var xKids = xParent.__kids;
	var yKids = yParent.__kids;

	var xLen = xKids.length;
	var yLen = yKids.length;

	var translated = false;
	var previousSibling = null;

	// PAIRWISE DIFF COMMON KIDS

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var diffReturn = _VirtualDom_diffHelp(xKids[i], yKids[i], eventNode);
		var domNode = diffReturn.__domNode;

		if (diffReturn.__translated)
		{
			translated = true;
		}

		if (diffReturn.__reinsert)
		{
			_VirtualDom_insertAfter(parentDomNode, domNode, previousSibling);
			previousSibling = domNode;
		}
		// An extension might have removed an element we have rendered before,
		// or moved it to another parent. In such cases, `parentDomNode.insertBefore(x, domNode)`
		// would throw errors. Keep the previous reference element in those cases – that should still
		// result in the correct element order, just with some element missing.
		else if (domNode.parentNode === parentDomNode)
		{
			previousSibling = domNode;
		}
	}

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		for (var i = yLen; i < xLen; i++)
		{
			_VirtualDom_removeVisit(xKids[i], true);
		}
	}
	else if (xLen < yLen)
	{
		for (var i = xLen; i < yLen; i++)
		{
			var y = yKids[i];
			var domNode = _VirtualDom_render(y, eventNode);
			_VirtualDom_appendChild(parentDomNode, domNode);
		}
	}

	return translated;
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(parentDomNode, xParent, yParent, eventNode)
{
	var xKids = xParent.__kids;
	var yKids = yParent.__kids;

	var xKidsMap = xParent.__kidsMap;
	var yKidsMap = yParent.__kidsMap;

	var xIndexLower = 0;
	var yIndexLower = 0;
	var xIndexUpper = xKids.length - 1;
	var yIndexUpper = yKids.length - 1;

	var domNodeLower = null;
	var domNodeUpper = null;

	var translated = false;

	var handleDiffReturn = function (diffReturn, upper)
	{
		var domNode = diffReturn.__domNode;

		if (diffReturn.__translated)
		{
			translated = true;
		}

		if (diffReturn.__reinsert)
		{
			if (upper)
			{
				_VirtualDom_insertBefore(parentDomNode, domNode, domNodeUpper);
				domNodeUpper = domNode;
			}
			else
			{
				_VirtualDom_insertAfter(parentDomNode, domNode, domNodeLower);
				domNodeLower = domNode;
			}
		}
		// An extension might have removed an element we have rendered before,
		// or moved it to another parent. In such cases, `parentDomNode.insertBefore(x, domNode)`
		// and `parentDomNode.moveBefore(x, domNode)` would throw errors. Keep the
		// previous reference element in those cases – that should still result in the correct
		// element order, just with some element missing.
		else if (domNode.parentNode === parentDomNode)
		{
			if (upper)
			{
				domNodeUpper = domNode;
			}
			else
			{
				domNodeLower = domNode;
			}
		}
	};

	while (true)
	{
		// Consume from the start until we get stuck.
		while (xIndexLower <= xIndexUpper && yIndexLower <= yIndexUpper)
		{
			var xKid = xKids[xIndexLower];
			var yKid = yKids[yIndexLower];
			var xKey = xKid.a;
			var yKey = yKid.a;
			var x = xKid.b;
			var y = yKid.b;

			if (xKey === yKey)
			{
				var diffReturn = _VirtualDom_diffHelp(x, y, eventNode);
				xIndexLower++;
				yIndexLower++;
				handleDiffReturn(diffReturn, false);
				continue;
			}

			var xMoved = false;

			if (xKey in yKidsMap)
			{
				xMoved = true;
			}
			else
			{
				_VirtualDom_removeVisit(x, true);
				xIndexLower++;
			}

			if (yKey in xKidsMap)
			{
				if (xMoved)
				{
					break;
				}
			}
			else
			{
				var domNode = _VirtualDom_render(y, eventNode);
				_VirtualDom_insertAfter(parentDomNode, domNode, domNodeLower);
				yIndexLower++;
				domNodeLower = domNode;
			}
		}

		// Consume from the end until we get stuck.
		while (xIndexUpper > xIndexLower && yIndexUpper > yIndexLower)
		{
			var xKid = xKids[xIndexUpper];
			var yKid = yKids[yIndexUpper];
			var xKey = xKid.a;
			var yKey = yKid.a;
			var x = xKid.b;
			var y = yKid.b;

			if (xKey === yKey)
			{
				var diffReturn = _VirtualDom_diffHelp(x, y, eventNode);
				xIndexUpper--;
				yIndexUpper--;
				handleDiffReturn(diffReturn, true);
				continue;
			}

			var xMoved = false;

			if (xKey in yKidsMap)
			{
				xMoved = true;
			}
			else
			{
				_VirtualDom_removeVisit(x, true);
				xIndexUpper--;
			}

			if (yKey in xKidsMap)
			{
				if (xMoved)
				{
					break;
				}
			}
			else
			{
				var domNode = _VirtualDom_render(y, eventNode);
				_VirtualDom_insertBefore(parentDomNode, domNode, domNodeUpper);
				yIndexUpper--;
				domNodeUpper = domNode;
			}
		}

		var swapped = false;

		// Check if the start or end can be unstuck by a swap.
		if (xIndexLower < xIndexUpper && yIndexLower < yIndexUpper)
		{
			var xKidLower = xKids[xIndexLower];
			var yKidLower = yKids[yIndexLower];
			var xKidUpper = xKids[xIndexUpper];
			var yKidUpper = yKids[yIndexUpper];

			var xKeyLower = xKidLower.a;
			var yKeyLower = yKidLower.a;
			var xKeyUpper = xKidUpper.a;
			var yKeyUpper = yKidUpper.a;

			if (xKeyLower === yKeyUpper)
			{
				var diffReturn = _VirtualDom_diffHelp(xKidLower.b, yKidUpper.b, eventNode);
				xIndexLower++;
				yIndexUpper--;
				_VirtualDom_moveBefore(parentDomNode, diffReturn.__domNode, domNodeUpper);
				handleDiffReturn(diffReturn, true);
				swapped = true;
			}

			if (xKeyUpper == yKeyLower)
			{
				var diffReturn = _VirtualDom_diffHelp(xKidUpper.b, yKidLower.b, eventNode);
				yIndexLower++;
				xIndexUpper--;
				_VirtualDom_moveAfter(parentDomNode, diffReturn.__domNode, domNodeLower);
				handleDiffReturn(diffReturn, false);
				swapped = true;
			}
		}

		// If no swap, stop consuming from start and end.
		if (!swapped)
		{
			break;
		}
	}

	// For the remaining items in the new virtual DOM, diff with the corresponding
	// old virtual DOM node (if any) and move it into the correct place.
	// This might result in more moves than technically needed, but:
	// - Moving nodes isn’t that slow. Diffing algorithms aren’t free either.
	// - In browsers supporting `.moveBefore()` unnecessary moves have no unwanted side effects.
	// - Elm has never had a “perfect” implementation for Keyed, and this should not
	//   be worse than the previous implementation.
	for (; yIndexLower <= yIndexUpper; yIndexLower++)
	{
		var yKid = yKids[yIndexLower];
		var yKey = yKid.a;
		var y = yKid.b;
		if (yKey in xKidsMap)
		{
			var x = xKidsMap[yKey];
			var diffReturn = _VirtualDom_diffHelp(x, y, eventNode);
			_VirtualDom_moveAfter(parentDomNode, diffReturn.__domNode, domNodeLower);
			handleDiffReturn(diffReturn, false);
		}
		else
		{
			var domNode = _VirtualDom_render(y, eventNode);
			_VirtualDom_insertAfter(parentDomNode, domNode, domNodeLower);
			domNodeLower = domNode;
		}
	}

	// Remove the remaining old virtual DOM nodes that aren’t present in the new virtual DOM.
	for (; xIndexLower <= xIndexUpper; xIndexLower++)
	{
		var xKid = xKids[xIndexLower];
		var xKey = xKid.a;
		if (!(xKey in yKidsMap)) {
			_VirtualDom_removeVisit(xKid.b, true);
		}
	}

	return translated;
}

var _VirtualDom_POSTFIX = '_elmW6BL';

// The field where we store the DOM nodes for the virtual node (see `_VirtualDom_wrap`).
// This needs to be different for each app instance, because a constant like
// `none = Html.text ""` can be used from multiple app instances, all of which
// need to keep track of their own DOM nodes. Instances are kept track of by assigning
// an incrementing number to `rootDomNode.elmInstance`. `_VirtualDom_instance` is set
// to the current instance in ` _VirtualDom_applyPatches` and `_VirtualDom_virtualize`.
var _VirtualDom_instance = '';
var _VirtualDom_instanceCount = 1;

function _VirtualDom_wrap(object)
{
	if (Object.prototype.hasOwnProperty.call(object, _VirtualDom_instance))
	{
		return;
	}

	// Add a non-enumerable property to not break Elm's equality checks.
	// You aren’t supposed to compare virtual nodes, but I’ve seen code
	// like `|> List.filter ((/=) Html.Extra.nothing)`.
	Object.defineProperty(object, _VirtualDom_instance, {
		value: {
			// We only read from `x.__oldDomNodes`. Uses `__i`. Is set to `__newDomNodes` at each render.
			__oldDomNodes: [],
			// This is set to a new, empty array on each render. We push to `y.__newDomNodes`. The reason we have to have two arrays is because the same virtual node can be used multiple times, so sometimes `x === y`.
			__newDomNodes: [],
			__renderedAt: 0,
			// The index of the next DOM node in `__oldDomNodes` to use.
			__i: 0
		}
	});
}

function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, newVirtualNode, eventNode)
{
	_VirtualDom_renderCount++;

	var instance = rootDomNode.elmInstance || _VirtualDom_instanceCount++;
	_VirtualDom_instance = '_' + instance;

	var diffReturn = _VirtualDom_diffHelp(oldVirtualNode, newVirtualNode, eventNode);
	// We can’t do anything about `diffReturn.__translated` or
	// `diffReturn.__reinsert` here, because we don’t know the parent of the
	// root node. Note that `rootDomNode.parentNode` cannot be used, because if
	// the root node is a text node and it has been translated, it is most
	// likely replaced by other nodes (so the original node is not attached to
	// the DOM anymore). Returning `Html.text` at the top level of `view` and
	// expecting it to be translatable is a bit of an edge case anyway.
	var newDomNode = diffReturn.__domNode;

	newDomNode.elmInstance = instance;
	_VirtualDom_instance = '';

	return newDomNode;
}

function _VirtualDom_applyPatchRedraw(x, y, eventNode)
{
	// Remove the old node. Well, just visit it for removal, but don’t remove the actual DOM node.
	// We want to use `replaceChild` below instead. We have already increased the counter in
	// `_VirtualDom_diffHelp`, so decrease it back first.
	x[_VirtualDom_instance].__i--;
	_VirtualDom_removeVisit(x, false);

	// We have already pushed the DOM node for this virtual node in `_VirtualDom_diffHelp`. Pop it off.
	// The `_VirtualDom_render` call below will push a new DOM node.
	var domNode = y[_VirtualDom_instance].__newDomNodes.pop();
	var parentNode = domNode.parentNode;
	var isTextNode = domNode.nodeType === 3;
	var newNode = _VirtualDom_render(y, eventNode);

	// An extension might have removed the element. In this case, we are redrawing because `x` and `y`
	// have changed a lot, implying that the structure has changed significantly, and that they can’t
	// be diffed normally. This means that the extension probably meant to remove the old element, but
	// not the new one, so return that this element is missing so that it can be re-inserted into the
	// parent. An example of this is Google Translate: It removes our text nodes and replaces them.
	// Later we might want to replace that text node with some element.
	if (parentNode)
	{
		parentNode.replaceChild(newNode, domNode);
		return {
			__domNode: newNode,
			__translated: isTextNode && domNode.data !== x.__text,
			__reinsert: false
		}
	}
	else
	{
		return {
			__domNode: newNode,
			__translated: isTextNode,
			__reinsert: true
		}
	}
}

/*
This is a mapping between attribute names and their corresponding boolean properties,
and only the ones where the attribute name is different from the property name
(usually in casing – attributes are case insensitive, and returned lowercase).

The mapping currently only lists the ones that have dedicated functions in elm/html.

There are more though! Running the following code in the console gives more results:

[...new Set(Object.getOwnPropertyNames(window).filter(d => d.startsWith('HTML') || d === 'Node' || d === 'Element' || d === 'EventTarget').flatMap(d => {c = window[d]; m = c.name.match(/^HTML(\w+)Element$/); e = document.createElement(m ? m[1].replace('Anchor', 'a').replace('Paragraph', 'p').replace('Image', 'img').replace('Media', 'video').replace(/^([DOU])List$/, '$1l').toLowerCase() : 'div'); return Object.getOwnPropertyNames(c.prototype).filter(n => typeof e[n] === 'boolean')}))].filter(n => /[A-Z]/.test(n)).sort()

Potential candidates to support (should probably add to elm/html first):
disablePictureInPicture – video
playsInline – video
formNoValidate – button, input

Not useful with Elm:
noModule – script
shadowRootClonable – template
shadowRootDelegatesFocus – template
shadowRootSerializable – template

Legacy/deprecated:
allowFullscreen – iframe (use allow="fullscreen" instead)
allowPaymentRequest – iframe (use allow="payment" instead)
noHref - area (image maps)
noResize – frame (not iframe)
noShade – hr
trueSpeed – marquee

Special:
defaultChecked
defaultMuted
defaultSelected

No corresponding attribute:
disableRemotePlayback
isConnected
isContentEditable
preservesPitch
sharedStorageWritable
willValidate

Unclear:
adAuctionHeaders
browsingTopics

Regarding the special ones: `<input checked>` results in `.defaultChecked === true`. Similarly, setting `input.defaultChecked = true` results in `input.outerHTML === '<input checked="">'`. `input.checked = true` does _not_ result in an attribute though: `.checked` has no corresponding attribute. However, when serializing
`Html.input [ Html.Attributes.checked True ] []` to HTML, `<input checked>` is the most reasonable choice.
So when virtualizing, we actually want to turn the `checked` attribute back into a boolean "checked" property in Elm
(even if according to the DOM, it's `.defaultChecked`). Same thing for `muted` and `selected`.
*/
var _VirtualDom_camelCaseBoolProperties = {
	novalidate: 'noValidate',
	readonly: 'readOnly',
	ismap: 'isMap'
};

// Used for server side rendering to keep track of which elements to
// virtualize. This is added to _all_ nodes (except text nodes) in
// `_VirtualDom_organizeFacts`. Server side rendering renders _all_ string and
// boolean facts as attributes, including this one. `_VirtualDom_applyProps`
// and `_VirtualDom_removeProps` _ignore_ this property, in order not to
// clutter the browser dev tools. `_VirtualDom_virtualize` only virtualizes
// children with this attribute. This way it knows which elements are “ours”
// and which were inserted by third-party scripts (before the virtualization
// took place). The root node is allowed not to have this attribute though, in
// order not to force everyone to put this attribute on the node they mount the
// Elm app on. During the first render after virtualization, we remove this
// attribute from all elements, to unclutter the browser console. That happens
// via `_VirtualDom_virtualize` virtualizing it as an _attribute_ (not a
// property) which, when compared to the result of `view`, is diffed for
// removal.
var _VirtualDom_markerProperty = 'data-elm';

function _VirtualDom_virtualize(node)
{
	// The debugger has always done `_VirtualDom_virtualize(document)` instead of
	// `_VirtualDom_virtualize(document.body)` by mistake. To be backwards compatible
	// with elm/browser, support that here.
	if (node === _VirtualDom_doc)
	{
		node = _VirtualDom_doc.body;
	}

	var instance = _VirtualDom_instanceCount++;
	_VirtualDom_instance = '_' + instance;
	node.elmInstance = instance;

	var vNode = _VirtualDom_virtualizeHelp(node);
	_VirtualDom_instance = '';

	if (vNode)
	{
		return vNode;
	}

	// Backwards compatibility: Elm has always supported mounting onto any
	// node, even comment nodes. Text nodes, comment nodes, CDATA sections and
	// processing instructions all implement the `CharacterData` abstract
	// interface, so representing them as a text node should be fine. The whole
	// document, doctypes and document fragments are also nodes, but they are
	// increasingly silly to render into and have never worked with Elm.
	vNode = _VirtualDom_text('');
	vNode._.__newDomNodes.push(node);
	return vNode;
}

function _VirtualDom_virtualizeHelp(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		var vNode = _VirtualDom_text(node.textContent);
		_VirtualDom_wrap(vNode);
		vNode[_VirtualDom_instance].__newDomNodes.push(node);
		return vNode;
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return undefined;
	}


	// ELEMENT NODES

	var tag = node.localName;
	var attrList = __List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;

		// The `style` attribute and `node.style` are linked. While `node.style` contains
		// every single CSS property, it’s possible to loop over only the styles that have
		// been set via `node.style.length`. Unfortunately, `node.style` expands shorthand
		// properties and normalizes values. For example, `padding: 0` is turned into
		// `padding-top: 0px; padding-bottom: 0px; ...`.
		// The best bet is actually parsing the styles ourselves. Naively splitting on `;`
		// is not 100 % correct, for example it won’t work for `content: ";"`. It will work
		// in 99 % of cases though, since putting a semicolon in a value isn’t that common.
		// And even in those cases, nothing will break. We’ll just apply a few styles
		// unnecessarily at init.
		if (name === "style")
		{
			var parts = value.split(";");
			for (var j = parts.length; j--; )
			{
				var part = parts[j];
				var index = part.indexOf(":");
				if (index !== -1)
				{
					var cssKey = part.slice(0, index).trim();
					var cssValue = part.slice(index + 1).trim();
					attrList = __List_Cons(A2(_VirtualDom_style, cssKey, cssValue), attrList);
				}
			}
			continue;
		}

		var namespaceURI = attr.namespaceURI;
		var propertyName = _VirtualDom_camelCaseBoolProperties[name] || name;
		var propertyValue = node[propertyName];
		// Turning attributes into virtual DOM representations is not an exact science.
		// If someone runs an Elm `view` function and then serializes it to HTML, we need to guess:
		//
		// - how they chose to serialize it
		// - what the most likely virtual DOM representation is
		//
		// In elm/html, the convention is to use attributes rather than properties where possible,
		// which is good for virtualization – we can just turn most HTML attributes we find as-is
		// into virtual DOM attributes. But when we encounter `foo="bar"` we can’t know if it was
		// created using `Html.Attributes.attribute "foo" "bar"` or
		// `Html.Attributes.property "foo" (Json.Encode.string "bar")`.
		//
		// It's not the end of the world if we guess wrong, though, it just leads to a bit of
		// unnecessary DOM mutations on the first render.
		//
		// Do we need to use any of the functions in the “XSS ATTACK VECTOR CHECKS”
		// section while virtualizing? I don’t think so, because they will already
		// have executed at this point, and the first render will remove any disallowed
		// attributes.
		attrList = __List_Cons(
			// `Html.Attributes.value` sets the `.value` property to a string, because that’s the
			// only way to set the value of an input element. The `.value` property has no corresponding
			// attribute; the `value` attribute maps to the `.defaultValue` property. But when serializing,
			// the most likely way to do it is to serialize the `.value` property to the `value` attribute.
			name === 'value'
				? A2(_VirtualDom_property, name, value)
				:
			// Try to guess if the attribute comes from one of the functions
			// implemented using `boolProperty` in `Html.Attributes`.
			// See `Html.Attributes.spellcheck` for that exception.
			typeof propertyValue === 'boolean' && name !== 'spellcheck'
				? A2(_VirtualDom_property, propertyName, propertyValue)
				:
			// Otherwise, guess that it is an attribute. The user might have used `Html.Attributes.property`,
			// but there’s no way for us to know that.
			namespaceURI
				? A3(_VirtualDom_attributeNS, namespaceURI, name, value)
				: A2(_VirtualDom_attribute, name, value),
			attrList
		);
	}

	var namespace =
		node.namespaceURI === 'http://www.w3.org/1999/xhtml'
			? undefined
			: node.namespaceURI;
	var kidList = __List_Nil;

	// To create a text area with default text in HTML:
	// - correct: <textarea>default text</textarea>
	// - wrong: <textarea value="default text"></textarea> (value="default text" does nothing.)
	// In the DOM, that becomes an `HTMLTextAreaElement`, with `.value === "default text"`.
	// It contains a single text node with the text `"default text"` too.
	// When the user types into the text area, `.value` changes, but the inner text node stays unchanged.
	// In Elm, you need to use `Html.textarea [ Html.Attributes.value myValue ] []` to be able to set the value.
	// All in all, this means that the most useful virtualization is:
	// - Skip any children (most likely a single text node), because the Elm code most likely set none.
	// - Pick up `.value`, even though it wasn’t set as an attribute in HTML – but most likely is a property set by the Elm code.
	// Note that in <textarea>, HTML isn’t parsed as usual – it is more of a plain text element.
	if (node.localName === 'textarea')
	{
		attrList = __List_Cons(
			A2(_VirtualDom_property, 'value', node.value),
			attrList
		);
	}
	else
	{
		for (var kids = node.childNodes, i = kids.length; i--; )
		{
			var kid = kids[i];

			// Only virtualize “our” elements – see `_VirtualDom_markerProperty`.
			if (kid.nodeType === 1 && !kid.hasAttribute(_VirtualDom_markerProperty))
			{
				continue;
			}

			var kidNode = _VirtualDom_virtualizeHelp(kid);
			// `kidNode` is `undefined` for comment nodes – skip those. This allows
			// server side rendering to insert comments between two text nodes to
			// preserve them being parsed as two nodes, not as just one with the
			// text from both.
			if (kidNode)
			{
				kidList = __List_Cons(kidNode, kidList);
			}
		}

		if (_VirtualDom_divertHrefToApp && node.localName === 'a')
		{
			node.addEventListener('click', _VirtualDom_divertHrefToApp(node));
		}
	}

	var vNode = A4(_VirtualDom_nodeNS, namespace, tag, attrList, kidList);
	_VirtualDom_wrap(vNode);
	vNode[_VirtualDom_instance].__newDomNodes.push(node);
	return vNode;
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.__kids;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return Object.defineProperty({
		$: __2_NODE,
		__tag: keyedNode.__tag,
		__facts: keyedNode.__facts,
		__kids: kids,
		__namespace: keyedNode.__namespace,
		__descendantsCount: keyedNode.__descendantsCount
	}, _VirtualDom_instance, {
		value: keyedNode[_VirtualDom_instance]
	});
}

function _VirtualDom_attribute_(name, value)
{
	return A2(_VirtualDom_attribute, name, value);
}

function _VirtualDom_node_(tag, facts, kids)
{
	return A3(_VirtualDom_node, tag, facts, kids);
}

export { _VirtualDom_init, _VirtualDom_attribute_, _VirtualDom_text, _VirtualDom_node_, _VirtualDom_virtualize };
