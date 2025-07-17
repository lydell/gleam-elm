/*

import Elm.Kernel.Utils exposing (Tuple2)

*/

import {
	NonEmpty,
} from '../gleam.mjs';


var _JsArray_empty = function()
{
    return [];
};

var _JsArray_singleton = function(value)
{
    return [value];
};

var _JsArray_length = function(array)
{
    return array.length;
};

var _JsArray_initialize = function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
};

var _JsArray_initializeFromList = function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls instanceof NonEmpty; i++)
    {
        result[i] = ls.head;
        ls = ls.tail;
    }

    result.length = i;
    return [result, ls];
};

var _JsArray_unsafeGet = function(index, array)
{
    return array[index];
};

var _JsArray_unsafeSet = function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
};

var _JsArray_push = function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
};

var _JsArray_foldl = function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = func(array[i], acc);
    }

    return acc;
};

var _JsArray_foldr = function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = func(array[i], acc);
    }

    return acc;
};

var _JsArray_map = function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
};

var _JsArray_indexedMap = function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(offset + i, array[i]);
    }

    return result;
};

var _JsArray_slice = function(from, to, array)
{
    return array.slice(from, to);
};

var _JsArray_appendN = function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
};

export {
    _JsArray_appendN,
    _JsArray_empty,
    _JsArray_foldl,
    _JsArray_foldr,
    _JsArray_indexedMap,
    _JsArray_initialize,
    _JsArray_initializeFromList,
    _JsArray_length,
    _JsArray_map,
    _JsArray_push,
    _JsArray_singleton,
    _JsArray_slice,
    _JsArray_unsafeGet,
    _JsArray_unsafeSet,
};
