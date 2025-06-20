/*

import Elm.Kernel.Scheduler exposing (binding, succeed)
import Elm.Kernel.Utils exposing (Tuple0)

*/

import {
	_Scheduler_binding as __Scheduler_binding,
	_Scheduler_succeed as __Scheduler_succeed,
} from './scheduler.ffi.mjs';


function _Process_sleep(time)
{
	return __Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(__Scheduler_succeed(undefined));
		}, time);

		return function() { clearTimeout(id); };
	});
}

export {
	_Process_sleep,
};
