import Lean

namespace Luthm

open Lean

structure Info where
  name : Name
  range : DeclarationRange
  hasSorry : Bool

structure TheoremInfo extends Info where

inductive DocInfo where
  | theoremInfo : TheoremInfo → DocInfo

def TheoremInfo.ofTheoremVal (v : TheoremVal) : CoreM TheoremInfo := do
  match ← findDeclarationRanges? v.name with
  | some range =>
    return {
      name := v.name,
      range := range.range,
      hasSorry := false
    }
  | none => throwError s!"Declaration range not found for {v.name}"

namespace DocInfo

def skip (n : Name) : CoreM Bool := do
  match ← findDeclarationRanges? n with
  | some _ => return false
  | none => return true

def ofConstant (name : Name) (info : ConstantInfo) : CoreM (Option DocInfo) := do
  if (← skip name) then return none
  match info with
  | .thmInfo i => return some <| DocInfo.theoremInfo (← TheoremInfo.ofTheoremVal i)
  | _ => return none

def getKindDescription : DocInfo → String
  | theoremInfo _ => "theorem"

end DocInfo

end Luthm
