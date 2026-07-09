# 05 — CI & release-readiness

Stand up continuous integration and lock down the branches, so every change is built, tested, and
gated — and so the project is _ready_ for the release phase without yet configuring releases.

## First CI workflow

Add a CI workflow that, on every push and pull request, sets up the toolchain (reuse the Nix flake
from chapter [03](./03-local-dev-environment.md)), then runs the quality gates from chapter
[04](./04-quality-gates.md): build, test, format-check, lint. This is the minimum gate; the job
names it emits are what branch protection will require, so name them deliberately.

## Branch protection

Branch protection is the once-per-project platform setup that enforces the branch model (`develop`
integrates, `master` mirrors releases, CI promotes). It is owned by
[`tools/git/branch-protection/`](../../tools/git/branch-protection/) — **linked, not copied here**.
Follow its [first-run enablement](../../tools/git/branch-protection/first-run-enablement.md) to turn
Actions/CI on with write permission after the first push, then apply the rulesets via its `setup.sh`
scripts.

The `REQUIRED_CHECKS` you protect on must match the CI job names above — see the branch-protection
README.

## Hand-off to the release phase

Release _setup_ — the release tool (e.g. release-plz), Trusted Publishing / OIDC, changelog
automation, binary distribution — lives in the [release workflow](../release-workflow/README.md) and
its language bindings, **not** here. Bootstrap only ensures the project is ready for it: CI is
green, branches are protected, and the default branch is set. When that holds, move to the release
phase.

## Automation

`bootstrap-ci` scaffolds the CI workflow (GitHub Actions / GitLab CI), reusing the project flake.
The CI + protection steps above are the SoT; see
[07 — Automation with cog](./07-automation-with-cog.md).
