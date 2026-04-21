# Publishing to Hex

This guide explains how Releaser publishes monorepo packages to Hex in
the correct order, handling internal dependencies automatically.

## The problem

In a monorepo, packages depend on each other via `path:` references:

```elixir
# apps/api/mix.exs
defp deps do
  [{:my_core, path: "../core"}]
end
```

But Hex doesn't understand `path:` — it needs version constraints:

```elixir
{:my_core, "~> 1.1"}
```

So to publish `api`, you need to:

1. First publish `core` to Hex
2. Change `api`'s dep from `path:` to the published version
3. Publish `api`
4. Change everything back to `path:` for local development

With 34 packages and nested dependencies, doing this manually is painful.
Releaser automates the entire process.

## How it works

### Step 1: See the plan

```bash
$ mix releaser.publish --dry-run

=== Releaser Publish ===

Level 0:
  my_core v1.1.0

Level 1:
  my_api v1.2.4 (deps: my_core)
  my_worker v0.5.1 (deps: my_core)

--dry-run: nothing will be published

my_api mix.exs changes:
  {:my_core, path: "..."} → {:my_core, "~> 1.1"}

my_worker mix.exs changes:
  {:my_core, path: "..."} → {:my_core, "~> 1.1"}
```

This shows:
- **Level 0**: Packages with no internal deps are published first
- **Level 1**: Packages that depend on level 0
- **Path replacement**: What `path:` deps become

### Step 2: Publish

```bash
$ mix releaser.publish
```

For each package (in dependency order), Releaser:

1. Backs up the original `mix.exs`
2. Replaces `{:my_core, path: "../core"}` → `{:my_core, "~> 1.1"}`
3. Injects `package/0` with license and links if missing
4. Runs `mix hex.publish --yes`
5. Restores the original `mix.exs`

If **any** publish fails, all `mix.exs` files are restored immediately.

### Step 3: Verify

After publishing, your `mix.exs` files are back to using `path:` for
local development. Nothing changes in your working tree.

## Publish options

### Bump before publishing

```bash
# Bump all packages by patch before publishing
$ mix releaser.publish --bump patch
```

### Publish specific packages

```bash
# Only publish my_api (automatically includes my_core because it depends on it)
$ mix releaser.publish --only my_api
```

This resolves transitive dependencies: if `api` depends on `core`, and
`core` depends on `openssl`, all three are published in the right order.

### Publish to a Hex organization

```bash
$ mix releaser.publish --org my_company
```

## Real-world example

Here's a 34-package monorepo with 4 levels of dependencies:

```bash
$ mix releaser.publish --dry-run

=== Releaser Publish ===

Level 0:
  cfdi_catalogos v4.0.16
  cfdi_complementos v4.0.17
  cfdi_transform v4.0.14
  clir_openssl v0.0.17
  saxon_he v12.5.2
  ... (23 more)

Level 1:
  cfdi_csd v4.0.16 (deps: clir_openssl)
  cfdi_designs v1.0.0 (deps: cfdi_xml2json, cfdi_utils, cfdi_types, cfdi_complementos)

Level 2:
  cfdi_xml v4.0.18 (deps: cfdi_csd, cfdi_transform, cfdi_complementos, cfdi_catalogos, cfdi_xsd, saxon_he)
  sat_auth v1.0.1 (deps: cfdi_csd)

Level 3:
  cfdi_cancelacion v0.0.1 (deps: sat_auth)
  cfdi_descarga v0.0.1 (deps: sat_auth)

cfdi_csd mix.exs changes:
  {:clir_openssl, path: "..."} → {:clir_openssl, "~> 0.0"}

cfdi_xml mix.exs changes:
  {:cfdi_csd, path: "..."} → {:cfdi_csd, "~> 4.0"}
  {:cfdi_transform, path: "..."} → {:cfdi_transform, "~> 4.0"}
  {:cfdi_complementos, path: "..."} → {:cfdi_complementos, "~> 4.0"}
  {:cfdi_catalogos, path: "..."} → {:cfdi_catalogos, "~> 4.0"}
  {:cfdi_xsd, path: "..."} → {:cfdi_xsd, "~> 4.0"}
  {:saxon_he, path: "..."} → {:saxon_he, "~> 12.5"}
```

## The `package/0` injection

Many monorepo packages don't have `package/0` defined because they're not
published individually. Releaser automatically injects it during publish:

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/me/project"},
    files: ~w(lib mix.exs README.md LICENSE)
  ]
end
```

You can customize the defaults in your config:

```elixir
releaser: [
  publisher: [
    package_defaults: [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/me/project"},
      files: ~w(lib priv mix.exs README.md LICENSE)
    ]
  ]
]
```

## Prerequisites

- Each app must have a `description` in its `mix.exs`
- You must be authenticated: `mix hex.user auth`
- The app must compile without errors

## Before publishing: check status

Use `mix releaser.status` to see what needs publishing:

```bash
$ mix releaser.status

=== Release Status ===

Package              Local       Hex         Status
cfdi_xml             4.0.19      4.0.18      ahead
cfdi_csd             4.0.16      4.0.16      published
cfdi_complementos    4.0.18-dev.1  4.0.17    pre-release
my_new_app           0.1.0       —           unpublished

2 package(s) need publishing.
Run mix releaser.publish --dry-run to see the plan.
```

## Recommended workflow

```bash
# 1. Develop with pre-release tags
mix releaser.bump cfdi_xml patch --tag dev
# ... make changes ...
mix releaser.bump cfdi_xml patch --tag dev

# 2. When ready, release
mix releaser.bump cfdi_xml release

# 3. Check what's pending
mix releaser.status

# 4. Preview the publish plan
mix releaser.publish --dry-run

# 5. Publish
mix releaser.publish
```
