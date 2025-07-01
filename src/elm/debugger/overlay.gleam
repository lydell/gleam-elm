// BLOCKERS

pub type BlockerType {
  BlockNone
  BlockMost
  BlockAll
}

pub fn to_blocker_type(is_paused: Bool) -> BlockerType {
  case is_paused {
    True -> BlockAll
    False -> BlockNone
  }
}
