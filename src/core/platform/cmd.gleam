pub type Cmd(msg)

pub fn none() -> Cmd(msg) {
  batch([])
}

@external(javascript, "../platform.ffi.mjs", "_Platform_batch")
pub fn batch(cmds: List(Cmd(msg))) -> Cmd(msg)
