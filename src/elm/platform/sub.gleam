pub type Sub(msg)

pub fn none() -> Sub(msg) {
  batch([])
}

@external(javascript, "../platform.ffi.mjs", "_Platform_batch")
pub fn batch(cmds: List(Sub(msg))) -> Sub(msg)
