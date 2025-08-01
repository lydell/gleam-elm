/*

import Time exposing (customZone, Name, Offset)
import Elm.Kernel.List exposing (Nil)
import Elm.Kernel.Scheduler exposing (binding, succeed)

*/

import {
	_Scheduler_binding as __Scheduler_binding,
	_Scheduler_rawSpawn,
	_Scheduler_succeed as __Scheduler_succeed,
} from './scheduler.ffi.mjs';


function _Time_now(millisToPosix)
{
	return __Scheduler_binding(function(callback)
	{
		callback(__Scheduler_succeed(millisToPosix(Date.now())));
	});
}

var _Time_setInterval = function(interval, task)
{
	return __Scheduler_binding(function(callback)
	{
		var id = setInterval(function() { _Scheduler_rawSpawn(task); }, interval);
		return function() { clearInterval(id); };
	});
};

function _Time_here()
{
	return __Scheduler_binding(function(callback)
	{
		callback(__Scheduler_succeed(
			__Time_customZone(-(new Date().getTimezoneOffset()), __List_Nil)
		));
	});
}


function _Time_getZoneName()
{
	return __Scheduler_binding(function(callback)
	{
		try
		{
			var name = __Time_Name(Intl.DateTimeFormat().resolvedOptions().timeZone);
		}
		catch (e)
		{
			var name = __Time_Offset(new Date().getTimezoneOffset());
		}
		callback(__Scheduler_succeed(name));
	});
}

export {
	_Time_now,
	_Time_setInterval,
};
