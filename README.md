[![CI](https://github.com/woylie/ecto_nested_changeset/actions/workflows/ci.yml/badge.svg)](https://github.com/woylie/ecto_nested_changeset/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/woylie/ecto_nested_changeset/badge.svg?branch=main)](https://coveralls.io/github/woylie/ecto_nested_changeset?branch=main)

# EctoNestedChangeset

This is an experimental package for manipulating nested Ecto changesets.

## Installation

Add `ecto_nested_changeset` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_nested_changeset, "~> 0.1.0"}
  ]
end
```

See the module documentation of `EctoNestedChangeset` for usage examples.

## Example application

```bash
cd example
mix setup
mix phx.server
```

Access the list of pet owners at http://localhost:4000.
