# luthm

Tool to list unproved (proved by `sorryAx`) theorems in Lean 4.

Status: **WIP**

## Architecture

**Below here is unimplemented and may change in the future.**

Example, below theorem proved by `sorry` in `Foo/Bar/Basic.lean` in module `Test`.

```lean
theorem Foo.Bar.DifficultTheorem : 1 + 1 = 2 := by
  sorry
```

Run luthm, First create `.lake/build/luthm/Test/Foo/Bar/Basic.json`.

```json
[
  {
    "name": "Foo.Bar.DifficultTheorem",
    "hasSorry": true,
    "range": "L1-L2"
  }
]
```

And then, create index file `.lake/build/luthm/Test/index.json`.

```json
{
  "Test": [
    {
      "file": "Foo/Bar/Basic.lean",
      "unproved": [
        {
          "name": "Foo.Bar.DifficultTheorem"
          "hasSorry": true,
          "range": "L1-L2"
        }
      ]
    }
  ]
}
```

## Automate Proof bounty dashboard by GitHub Actions

GitHub Actions can be configured to run luthm automatically and create (or update) issue by refering to `.lake/build/luthm/*/index.json` when pushing commit to default branch. So we can create proof bounty dashboard like [Renovate's Dependency Dashboard](https://docs.renovatebot.com/key-concepts/dashboard/). It might be help to someone contribute (or fill proof) your repository.

## Development

```
cd ./Test
lake build Test:luthm
```

## Referrences

- [Std4's `proof_wanted`](https://github.com/leanprover/std4/blob/main/Std/Util/ProofWanted.lean)
  - [std4/#401](https://github.com/leanprover/std4/pull/401)
