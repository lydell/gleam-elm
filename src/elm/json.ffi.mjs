/*

import Array exposing (initialize)
import Elm.Kernel.List exposing (Cons, Nil, fromArray)
import Elm.Kernel.Utils exposing (Tuple2)
import Json.Decode as Json exposing (Field, Index, OneOf, Failure, errorToString)
import List exposing (reverse)
import Maybe exposing (Just, Nothing)
import Result exposing (Ok, Err, isOk)

*/

import {
	Empty,
	Error as GleamError,
	List,
	NonEmpty,
	Ok,
} from '../gleam.mjs';
import {
	reverse as __List_reverse,
} from '../../gleam_stdlib/gleam/list.mjs';
import {
	initialize as __Array_initialize,
} from './array.mjs';
import {
	Failure as __Json_Failure,
	Field as __Json_Field,
	Index as __Json_Index,
	OneOf as __Json_OneOf,
} from './json/decode.mjs';

var __1_SUCCEED = 0;
var __1_FAIL = 1;
var __1_PRIM = 2;
var __1_LIST = 3;
var __1_ARRAY = 4;
var __1_NULL = 5;
var __1_FIELD = 6;
var __1_INDEX = 7;
var __1_KEY_VALUE = 8;
var __1_MAP = 9;
var __1_AND_THEN = 10;
var __1_ONE_OF = 11;



/**__DEBUG/
function _Json_errorToString(error)
{
	return __Json_errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: __1_SUCCEED,
		__msg: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: __1_FAIL,
		__msg: msg
	};
}

function _Json_decodePrim(decoder)
{
	return function()
	{
		return { $: __1_PRIM, __decoder: decoder };
	}
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? new Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? new Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? new Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? new Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return new Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? new Ok(value)
		: (value instanceof String)
			? new Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: __1_LIST, __decoder: decoder }; }
function _Json_decodeArray(decoder) { return { $: __1_ARRAY, __decoder: decoder }; }

function _Json_decodeNull(value) { return { $: __1_NULL, __value: value }; }

var _Json_decodeField = function(field, decoder)
{
	return {
		$: __1_FIELD,
		__field: field,
		__decoder: decoder
	};
};

var _Json_decodeIndex = function(index, decoder)
{
	return {
		$: __1_INDEX,
		__index: index,
		__decoder: decoder
	};
};

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: __1_KEY_VALUE,
		__decoder: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: __1_MAP,
		__func: f,
		__decoders: decoders
	};
}

var _Json_andThen = function(decoder, callback)
{
	return {
		$: __1_AND_THEN,
		__decoder: decoder,
		__callback: callback
	};
};

function _Json_oneOf(decoders)
{
	return {
		$: __1_ONE_OF,
		__decoders: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = function(d1, f)
{
	return _Json_mapMany(f, [d1]);
};

var _Json_map2 = function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
};

var _Json_map3 = function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
};

var _Json_map4 = function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
};

var _Json_map5 = function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
};

var _Json_map6 = function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
};

var _Json_map7 = function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
};

var _Json_map8 = function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
};


// DECODE

var _Json_runOnString = function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return new GleamError(new __Json_Failure('This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
};

var _Json_run = function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
};

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case __1_PRIM:
			return decoder.__decoder(value);

		case __1_NULL:
			return (value === null)
				? new Ok(decoder.__value)
				: _Json_expecting('null', value);

		case __1_LIST:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.__decoder, value, List.fromArray);

		case __1_ARRAY:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.__decoder, value, _Json_toElmArray);

		case __1_FIELD:
			var field = decoder.__field;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.__decoder, value[field]);
			return (result instanceof Ok) ? result : new GleamError(new __Json_Field(field, result[0]));

		case __1_INDEX:
			var index = decoder.__index;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.__decoder, value[index]);
			return (result instanceof Ok) ? result : new GleamError(new __Json_Index(index, result[0]));

		case __1_KEY_VALUE:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = new Empty;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.__decoder, value[key]);
					if (!(result instanceof Ok))
					{
						return new GleamError(new __Json_Field(key, result[0]));
					}
					keyValuePairs = new NonEmpty([key, result[0]], keyValuePairs);
				}
			}
			return new Ok(__List_reverse(keyValuePairs));

		case __1_MAP:
			var answer = decoder.__func;
			var decoders = decoder.__decoders;
			var args = new Array(decoders.length);
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!(result instanceof Ok))
				{
					return result;
				}
				args[i] = result[0];
			}
			return new Ok(answer.apply(null, args));

		case __1_AND_THEN:
			var result = _Json_runHelp(decoder.__decoder, value);
			return (!(result instanceof Ok))
				? result
				: _Json_runHelp(decoder.__callback(result[0]), value);

		case __1_ONE_OF:
			var errors = new Empty;
			for (var temp of decoder.__decoders)
			{
				var result = _Json_runHelp(temp, value);
				if (result instanceof Ok)
				{
					return result;
				}
				errors = new NonEmpty(result[0], errors);
			}
			return new GleamError(new __Json_OneOf(__List_reverse(errors)));

		case __1_FAIL:
			return new GleamError(new __Json_Failure(decoder.__msg, _Json_wrap(value)));

		case __1_SUCCEED:
			return new Ok(decoder.__msg);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!(result instanceof Ok))
		{
			return new GleamError(new __Json_Index(i, result[0]));
		}
		array[i] = result[0];
	}
	return new Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return __Array_initialize(array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return new GleamError(new __Json_Failure('Expecting ' + type, _Json_wrap(value)));
}


// ENCODE

var _Json_encode = function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
};

function _Json_wrap(value) { return value; }
function _Json_unwrap(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
};

var _Json_addEntry = function(value, array)
{
	array.push(_Json_unwrap(value));
	return array;
};

var _Json_encodeNull = _Json_wrap(null);


// GLEAM EXTRAS

var _Json_isSimpleFieldNameRegex = /^[a-z][a-z0-9]$/i;

function _Json_isSimpleFieldName(name)
{
	return _Json_isSimpleFieldNameRegex.test(name);
}

export {
	_Json_addEntry,
	_Json_addField,
	_Json_andThen,
	_Json_decodeBool,
	_Json_decodeArray,
	_Json_decodeField,
	_Json_decodeFloat,
	_Json_decodeIndex,
	_Json_decodeInt,
	_Json_decodeKeyValuePairs,
	_Json_decodeList,
	_Json_decodeNull,
	_Json_decodeString,
	_Json_decodeValue,
	_Json_emptyArray,
	_Json_emptyObject,
	_Json_encode,
	_Json_encodeNull,
	_Json_fail,
	_Json_isSimpleFieldName,
	_Json_map1 as _Json_map,
	_Json_map2,
	_Json_map3,
	_Json_map4,
	_Json_map5,
	_Json_map6,
	_Json_map7,
	_Json_map8,
	_Json_oneOf,
	_Json_run,
	_Json_runHelp,
	_Json_runOnString,
	_Json_succeed,
	_Json_unwrap,
	_Json_wrap,
};
