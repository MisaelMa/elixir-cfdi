# `mix releaser.bump`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/mix/tasks/releaser.bump.ex#L1)

Bumps the semver version of an app and cascades patch bumps to dependents.

## Usage

    mix releaser.bump <app> <major|minor|patch>
    mix releaser.bump <app> <major|minor|patch> --tag dev
    mix releaser.bump <app> release
    mix releaser.bump <app> 2.0.0              # explicit version
    mix releaser.bump --list
    mix releaser.bump --all patch

## Pre-release tags

    mix releaser.bump my_app patch --tag dev    # 4.0.17 → 4.0.18-dev.1
    mix releaser.bump my_app patch --tag dev    # 4.0.18-dev.1 → 4.0.18-dev.2
    mix releaser.bump my_app patch --tag beta   # 4.0.18-dev.2 → 4.0.18-beta.1
    mix releaser.bump my_app release            # 4.0.18-beta.1 → 4.0.18

## Options

    --dry-run      Show what would change without modifying files
    --no-cascade   Only bump the specified app, skip dependents
    --no-hooks     Skip pre/post hooks
    --tag TAG      Pre-release tag (dev, beta, rc, alpha, etc.)
    --build BUILD  Build metadata (e.g., 20260420)
    --list         List all apps with current versions
    --all TYPE     Bump all apps by the given type

---

*Consult [api-reference.md](api-reference.md) for complete listing*
