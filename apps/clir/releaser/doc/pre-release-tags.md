# Pre-release Tags

Releaser supports the full SemVer 2.0 pre-release lifecycle. This guide
explains how tags work, when to use each one, and the rules behind them.

## Why pre-release tags?

When you're developing a new feature across multiple packages, you don't
want to publish stable versions until everything is ready. Pre-release
tags let you:

- Publish test versions to Hex without affecting stable users
- Iterate quickly (`dev.1 → dev.2 → dev.3`) without burning version numbers
- Promote through stages (`dev → beta → rc → stable`) as confidence grows
- Keep the same base version through the entire cycle

## The lifecycle

Here's a real-world example. You're adding CartaPorte 3.1 support to
`cfdi_complementos`, currently at `4.0.17`:

```bash
# Start development — creates first dev pre-release
$ mix releaser.bump cfdi_complementos patch --tag dev
# 4.0.17 → 4.0.18-dev.1

# Fixed a bug in the XSD validation, bump again
$ mix releaser.bump cfdi_complementos patch --tag dev
# 4.0.18-dev.1 → 4.0.18-dev.2

# Another fix
$ mix releaser.bump cfdi_complementos patch --tag dev
# 4.0.18-dev.2 → 4.0.18-dev.3

# Feature is complete, promote to beta for QA
$ mix releaser.bump cfdi_complementos patch --tag beta
# 4.0.18-dev.3 → 4.0.18-beta.1
# Notice: base stays at 4.0.18!

# QA found a bug, fix and bump
$ mix releaser.bump cfdi_complementos patch --tag beta
# 4.0.18-beta.1 → 4.0.18-beta.2

# QA approved, promote to release candidate
$ mix releaser.bump cfdi_complementos patch --tag rc
# 4.0.18-beta.2 → 4.0.18-rc.1

# Everything looks good — release!
$ mix releaser.bump cfdi_complementos release
# 4.0.18-rc.1 → 4.0.18
```

The entire cycle used a single base version: `4.0.18`.

## Rules

There are three rules that control how tags behave:

### Rule 1: Clean version + tag = bump base + add tag

Starting from a stable version, adding a tag bumps the base first:

```bash
$ mix releaser.bump my_app patch --tag dev
# 1.0.0 → 1.0.1-dev.1
#          ^^^^^ bumped

$ mix releaser.bump my_app minor --tag dev
# 1.0.0 → 1.1.0-dev.1
#          ^^^^^ bumped
```

This ensures the dev version is **ahead** of the current stable.

### Rule 2: Same tag = increment number only

When you bump with the same tag, only the number increments. The base stays:

```bash
$ mix releaser.bump my_app patch --tag dev
# 1.0.1-dev.1 → 1.0.1-dev.2
#                         ^ only this changes

$ mix releaser.bump my_app patch --tag dev
# 1.0.1-dev.2 → 1.0.1-dev.3
```

This is for iterating within a stage. You're not done with dev, you're
just making more dev fixes.

### Rule 3: Different tag = keep base, switch tag

When you change tags (promote), the base version stays the same:

```bash
$ mix releaser.bump my_app patch --tag beta
# 1.0.1-dev.3 → 1.0.1-beta.1
#  ^^^^^ same     ^^^^^^ new tag

$ mix releaser.bump my_app patch --tag rc
# 1.0.1-beta.2 → 1.0.1-rc.1
#  ^^^^^ same      ^^^^ new tag
```

This makes sense because promoting from dev to beta doesn't change the
code — it just changes the confidence level.

## SemVer ordering

Hex respects SemVer 2.0 ordering. Pre-release versions are **always less
than** the stable version with the same number:

```
4.0.18-alpha.1 < 4.0.18-beta.1 < 4.0.18-dev.1 < 4.0.18-rc.1 < 4.0.18
```

> Tags are ordered alphabetically: `alpha < beta < dev < rc`.
> The stable version `4.0.18` is always greater than any `4.0.18-*`.

This means users with `{:my_app, "~> 4.0"}` will **not** get pre-release
versions unless they explicitly opt in with `{:my_app, "~> 4.0.18-dev"}`.

## Common tags

| Tag | When to use | Who installs it |
|---|---|---|
| `dev` | Active development, things may break | Only you and your CI |
| `alpha` | First round of internal testing | Internal team |
| `beta` | Feature-complete, looking for bugs | Adventurous early adopters |
| `rc` | Release candidate, should be stable | Anyone willing to test |

You can use any string as a tag. These are just conventions.

## With cascade

When you bump an app with a tag, cascaded dependents get a **plain patch
bump** (no tag). This is intentional — only the app you're actively
developing gets the pre-release tag:

```bash
$ mix releaser.bump cfdi_csd patch --tag dev --dry-run

Version changes:
  cfdi_csd                  4.0.16 → 4.0.17-dev.1   (direct)
  cfdi_xml                  4.0.18 → 4.0.19          (cascade)  ← no tag
  sat_auth                  1.0.1  → 1.0.2           (cascade)  ← no tag
```

## With publishing

`mix releaser.status` shows pre-release versions as a distinct status:

```
Package              Local            Hex         Status
cfdi_complementos    4.0.18-dev.3     4.0.17      pre-release
cfdi_xml             4.0.19           4.0.18      ahead
```

Pre-release versions are publishable to Hex but won't be installed by
default by users who have `~>` version constraints.
