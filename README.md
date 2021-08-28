# EctoNestedChangeset

This is an experimental package for manipulating nested Ecto changesets.

## Installation

Add `ecto_nested_changeset` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_nested_changeset, github: "woylie/ecto_nested_changeset", branch: "main"}
  ]
end
```

## Example application

```bash
cd example
mix setup
mix phx.server
```

Access the list of pet owners at `http://localhost:4000`.
