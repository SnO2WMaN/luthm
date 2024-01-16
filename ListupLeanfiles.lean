import Lean
import Std.Data.List

open Lean

def Lean.HashSet.fromArray [BEq α] [Hashable α] (xs : Array α) : Lean.HashSet α :=
  xs.foldr (flip .insert) .empty

inductive ProofStatus
  /- ? -/
  | missing
  | proved
  | stated
  | notStated

instance : ToString ProofStatus where
  toString
    | .missing => "missing"
    | .proved => "proved"
    | .stated => "stated"
    | .notStated => "notStated"

def mkUrlBuilder : IO (Option DeclarationRange → String) := do
  return fun range =>
    match range with
    | some r => s!"#L{r.pos.line}-L{r.endPos.line}"
    | none => ""

def statusOf (d : ConstantInfo) : CoreM ProofStatus := do
  if d.type.hasSorry then return .notStated
  else
    let some v := d.value? | throwError "Axioms not permitted!"
    if v.hasSorry then return .stated
    return .proved

def infoFor (n : Name) : CoreM (Option (System.FilePath × Name) × Option DeclarationRange × ProofStatus) := do
  let e ← getEnv
  let some d := e.find? n | return (none, none, .missing)

  let s <- statusOf d
  let range := DeclarationRanges.range <$> (← Lean.findDeclarationRanges? n)

  return (none, range, s)

structure TheoremInfo where
  name : Name
  range : DeclarationRange
  status : ProofStatus

def TheoremInfo.ofTheoremVal (v : TheoremVal) : CoreM TheoremInfo := do
  match ← findDeclarationRanges? v.name with
  | some range =>
    return {
      name := v.name,
      range := range.range,
      status := .proved
    }
  | none => throwError s!"Declaration range not found for {v.name}"

inductive DocInfo where
| theoremInfo : TheoremInfo → DocInfo

def skip (n : Name) : CoreM Bool := do
  match ← findDeclarationRanges? n with
  | some _ => return false
  | none => return true

def ofConstant (name : Name) (info : ConstantInfo) : CoreM (Option DocInfo) := do
  if (← skip name) then return none

  match info with
  | .thmInfo i =>
    return DocInfo.theoremInfo (← TheoremInfo.ofTheoremVal i)
  | _ => return none

def getOutput : CoreM (List (String × String × ProofStatus)) := do
  let env ← getEnv
  let relevantModules := HashSet.fromArray env.header.moduleNames

  for (name, cinfo) in env.constants.toList do
    let some modidx := env.getModuleIdxFor? name | unreachable!;
    let moduleName := env.allImportedModuleNames.get! modidx;

    -- dbg_trace s!"{moduleName} {name}";

    let ctx : Core.Context := {
        maxHeartbeats := 5000000,
        options := ← getOptions,
        fileName := ← getFileName,
        fileMap := ← getFileMap,
        catchRuntimeEx := true,
    }
    let analysis ← Prod.fst <$> (ofConstant name cinfo).toIO ctx { env := env }
    if let some dinfo := analysis then

    continue

  let urlBuilder ← mkUrlBuilder
  let infos ← (List.range' 1 10).mapM λ i => do
    let n := s!"thm_{i}".toName
    let data ← infoFor n
    return (n.toString, data)

  let a ← infos.mapM (λ (n, data) => do
    let (path, range, status) := data
    let url := urlBuilder range
    pure (n, url, status)
  )

  return a

def load (imports : Array Name) := do
  initSearchPath (← findSysroot)

  let env ← importModules (imports.map (Import.mk · false)) Options.empty

  let ctx: Core.Context := {
    fileName := default,
    fileMap := default,
  }

  Prod.fst <$> getOutput.toIO ctx { env := env }

def main (args : List String) : IO Unit := do
  let a ← load #[`MiscExamples]
  IO.println s!"Hello, ${a}"
