import «Luthm»
import Lean
import Cli

open Lean Cli Luthm
open IO System

def runDocGenCmd (p : Parsed) : IO UInt32 := do
  let a ← load #[`Luthm]
  IO.println s!"Hello, ${a}"

  return 0

def runSingleCmd (p : Parsed) : IO UInt32 := do
  let relevantModules := #[p.positionalArg! "module" |>.as! String |> String.toName]
  let sourceUri := p.positionalArg! "sourceUri" |>.as! String

  dbg_trace s!"{relevantModules}"
  let a ← load relevantModules

  FS.createDirAll $ FilePath.mk "." / ".lake" / "build" / "luthm"
  return 0

def singleCmd := `[Cli|
  single VIA runSingleCmd;
  "Only generate the documentation for the module it was given, might contain broken links unless all documentation is generated."

  FLAGS:
    ink; "Render the files with LeanInk in addition"

  ARGS:
    module : String; "The module to generate the HTML for. Does not have to be part of topLevelModules."
    sourceUri : String; "The sourceUri as computed by the Lake facet"
]

def docGenCmd : Cmd := `[Cli|
  "luthm" VIA runDocGenCmd;
  ["0.1.0"]
  "Tool to list theorems with sorry in Lean 4."

  SUBCOMMANDS:
    singleCmd
]

def main (args : List String) : IO UInt32 :=
  docGenCmd.validate args
