import Lean

open Lean

def Lean.HashSet.fromArray [BEq α] [Hashable α] (xs : Array α) : Lean.HashSet α :=
  xs.foldr (flip .insert) .empty
