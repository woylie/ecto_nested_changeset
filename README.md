[![CI](https://github.com/woylie/ecto_nested_changeset/actions/workflows/ci.yml/badge.svg)](https://github.com/woylie/ecto_nested_changeset/actions/workflows/ci.yml) [![Hex](https://img.shields.io/hexpm/v/ecto_nested_changeset)](https://hex.pm/packages/ecto_nested_changeset) [![Coverage Status](https://coveralls.io/repos/github/woylie/ecto_nested_changeset/badge.svg?branch=main)](https://coveralls.io/github/woylie/ecto_nested_changeset?branch=main)

# EctoNestedChangeset

This is an experimental package for manipulating nested Ecto changesets.

## Installation

Add `ecto_nested_changeset` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_nested_changeset, "~> 0.1.2"}
  ]
end
```

See the module documentation of `EctoNestedChangeset` for usage examples.

## Usage

```elixir
category = %Category{
  posts: [
    %Post{
      id: 1,
      comments: [
        %Comment{body: "potato", id: 1},
        %Comment{body: "you", id: 2}
      ],
      title: "must"
    },
    %Post{comments: [], id: 2, title: "young"}
  ]
}

category
|> Ecto.Changeset.change()
|> append_at(:posts, %Post{title: "Padawan", comments: []})
|> prepend_at([:posts, 0, :comments], %Comment{body: "ecneitaP"})
|> delete_at([:posts, 0, :comments, 1], mode: {:action, :delete})
|> insert_at([:posts, 1], %Post{title: "have"})
|> append_at([:posts, 2, :comments], %Comment{body: "my"})
|> update_at([:posts, 0, :comments, 0, :body], &String.reverse/1)
|> Ecto.Changeset.apply_changes()

%Category{
  posts: [
    %Post{
      comments: [
        %Comment{body: "Patience"},
        %Comment{body: "you", id: 2}
      ],
      id: 1,
      title: "must"
    },
    %Post{title: "have"},
    %Post{
      comments: [%Comment{body: "my"}],
      id: 2,
      title: "young"
    },
    %Post{title: "Padawan"}
  ]
}
```

## Example application

There is an example Phoenix application with a dynamic nested LiveView form in
the `/example` folder of the repository.

```bash
cd example
mix setup
mix phx.server
```

You can access the list of pet owners at http://localhost:4000.

## Status

This library has a very narrow purpose, which means that even though it is
young, it is unlikely that new functionality is going to be added or that the
API is going to change. Any issues that may arise will be dealt with swiftly.
