import Lake
open Lake DSL


package «luthm» where
  -- add package configuration options here

lean_lib «Luthm» where
  -- add library configuration options here

@[default_target]
lean_exe «luthm» where
  root := `Main
  supportInterpreter := true

require std from git "https://github.com/leanprover/std4" @ "main"
require Cli from git "https://github.com/leanprover/lean4-cli" @ "main"

module_facet luthm (mod) : FilePath := do
  let some luthm ← findLeanExe? `«luthm»
    | error "no luthm executable configuration found in workspace"
  let exeJob ← luthm.exe.fetch
  let modJob ← mod.leanArts.fetch
  let ws ← getWorkspace
  let pkg ← ws.packages.find? (·.isLocalModule mod.name)
  let libConfig ← pkg.leanLibConfigs.toArray.find? (·.isLocalModule mod.name)
  let imports ← mod.imports.fetch
  let depDocJobs ← BuildJob.mixArray <| ← imports.mapM fun mod => fetch <| mod.facet `luthm

  dbg_trace pkg.leanLibDir
  -- let depDocJobs ← BuildJob.mixArray <| ← imports.mapM fun mod => fetch <| mod.facet `luthm

  let buildDir := ws.root.buildDir
  let docFile := mod.filePath (buildDir / "luthm") "json"

  let srcUri := "file://";

  depDocJobs.bindAsync fun _ depDocTrace => do
  exeJob.bindAsync fun exeFile exeTrace => do
  modJob.bindSync fun _ modTrace => do
    let depTrace := mixTraceArray #[exeTrace, modTrace, depDocTrace]
    let trace ← buildFileUnlessUpToDate docFile depTrace do
      logStep s!"Analysing module: {mod.name}"
      proc {
        cmd := exeFile.toString
        args := #["single", mod.name.toString, srcUri]
        env := ← getAugmentedEnv
      }
    return (docFile, trace)

library_facet luthm (lib) : Unit := do
  let mods ← lib.modules.fetch
  let moduleJobs ← BuildJob.mixArray <| ← mods.mapM (fetch <| ·.facet `luthm)

  let exeJob ← «luthm».fetch

  let basePath := (←getWorkspace).root.buildDir / "luthm"
  let dataFile := basePath / "declarations" / "declaration-data-Lean.bmp"

  /-
  exeJob.bindAsync fun exeFile exeTrace => do
  moduleJobs.bindSync fun _ inputTrace => do
    let depTrace := mixTraceArray #[inputTrace, exeTrace]
    let trace ← buildFileUnlessUpToDate dataFile depTrace do
      logInfo "Documentation indexing"
      proc {
        cmd := exeFile.toString
        args := #["index"]
      }
    return (dataFile, trace)
  -/
  return .nil
