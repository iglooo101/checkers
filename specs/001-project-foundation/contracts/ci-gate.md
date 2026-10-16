# Contract: CI gate

The behavior the repository's CI promises, and that branch protection on `main` relies on.
Requirements: FR-005 to FR-009, FR-020; clarifications Q1, Q2, Q4, Q5.

## Trigger

- Every `push` to any branch except `main`, and manual dispatch. Commits reach `main` by
  fast-forward after passing on their branch, so `main` itself does not re-run CI.
- No pull request trigger: this repository lands work by fast-forwarding `main`.

## Required check

- Name: **`CI gate`**. It is the only check `main` requires, and no other workflow may use a job
  with this name (duplicate names make required checks ambiguous).
- It reports a result for every push it runs on, including documentation-only pushes.

## Classification of a push

| Changed files in the pushed range | Classification |
|---|---|
| Every file ends in `.md` | docs-only |
| Anything else (Swift, project files, scripts, `.gitignore`, workflow files, assets) | code |

The pushed range is `before..after` of the push. For a new branch it is the merge base with
`origin/main`..`after`.

## Outcomes

| Classification | Build and tests run? | `CI gate` result |
|---|---|---|
| docs-only | No | success |
| code, every step green | Yes | success |
| code, any blocking step fails | Yes | failure |
| classification step itself fails | — | failure |

## Blocking steps (code pushes)

Each fails `CI gate` and names its cause in the log:

1. Format check: `swift-format lint --strict` over app, test and engine sources.
2. Build and test with the `checkers` test plan (unit, UI and engine tests) on an iPhone 17
   simulator, iOS 26.2, Xcode 26.3, with compiler warnings treated as errors. SwiftLint runs
   inside the build; lint **errors** fail it, lint **warnings** are reported only.
3. String catalog check: the committed `Localizable.xcstrings` equals the result of syncing it
   with the strings the build extracted.

## Launch timing step (code pushes)

- Launch test (`Performance` test plan). Its measured cold-launch duration and the recorded local
  baseline are written to the job summary.
- Timing is report-only: CI runners have no recorded baseline, so a slow result never fails
  `CI gate`.
- A launch test that errors (for example, the app fails to launch) fails `CI gate`
  (Constitution III.5).

## Artifacts

- Test result bundles are uploaded for every code run, pass or fail.

## Budgets

- Docs-only push: `CI gate` reports within 2 minutes (SC-002).
- Code push: the full run finishes within 20 minutes (SC-006).

## Branch protection that depends on this contract

- `main` requires `CI gate`, non-strict, applied to administrators, with no pull request reviews.
- A commit is accepted on `main` only if `CI gate` passed for that exact commit. Fast-forwarding
  keeps commit SHAs, so a commit that passed on its feature branch is accepted (FR-008, FR-009).
