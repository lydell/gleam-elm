// Note: This JS function does not exist in Elm, but needs to be implemented
// with FFI in Gleam since it can return NaN in Elm. Gleam normally does not
// have NaN.
function _Basics_logBase(base, number)
{
	return Math.log(number) / Math.log(base);
}

export {
	_Basics_logBase,
};
