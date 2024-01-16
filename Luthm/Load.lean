import Lean
import Std.Data.List
import Luthm.DocInfo
import Luthm.Utils

namespace Luthm

open Lean

/-
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

def mkUrlBuilder : IO (Option DeclarationRange → String) := do
  return fun range =>
    match range with
    | some r => s!"#L{r.pos.line}-L{r.endPos.line}"
    | none => ""
-/

def statusOf (d : ConstantInfo) : Bool :=
  if d.type.hasSorry then true
  else
    match d.value? with
    | some v => v.hasSorry
    | none => false

def getOutput : CoreM (List (Nat)) := do
  let env ← getEnv
  let relevantModules := HashSet.fromArray env.header.moduleNames
  let allModules := env.header.moduleNames
  dbg_trace s!"{allModules}"

  -- let mut res := mkHashMap relevantModules.size
  for module in relevantModules do
    let some modIdx := env.getModuleIdx? module | unreachable!
    let moduleData := env.header.moduleData.get! modIdx
    let imports := moduleData.imports.map Import.module
    let a := moduleData.constants
      |>.filter statusOf
      |>.map (·.name)
    dbg_trace s!"{module}, {a}"

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
    let analysis ← Prod.fst <$> (DocInfo.ofConstant name cinfo).toIO ctx { env := env }
    if let some dinfo := analysis then
      -- dbg_trace s!"{dinfo.getKindDescription} {name}"

    continue

  /-
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
  -/

  return []

def load (imports : Array Name) : IO (List (Nat)) := do
  initSearchPath (← findSysroot)

  let env ← importModules (imports.map (Import.mk · false)) Options.empty

  let ctx: Core.Context := {
    maxHeartbeats := 100000000,
    fileName := default,
    fileMap := default,
  }

  Prod.fst <$> getOutput.toIO ctx { env := env }

end Luthm
