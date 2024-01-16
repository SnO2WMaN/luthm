import Lake
open Lake DSL

package «Test» where
  -- add package configuration options here

lean_lib «Test» where
  -- add library configuration options here

@[default_target]
lean_exe «test» where
  root := `Main

require «luthm» from "../"
