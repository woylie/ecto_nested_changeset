[![CI](https://github.com/woylie/ecto_nested_changeset/actions/workflows/ci.yml/badge.svg)](https://github.com/woylie/ecto_nested_changeset/actions/workflows/ci.yml) [![Hex](https://img.shields.io/hexpm/v/ecto_nested_changeset)](https://hex.pm/packages/ecto_nested_changeset) [![Coverage Status](https://coveralls.io/repos/github/woylie/ecto_nested_changeset/badge.svg?branch=main)](https://coveralls.io/github/woylie/ecto_nested_changeset?branch=main)

# EctoNestedChangeset

This is a package for manipulating nested
[Ecto](https://github.com/elixir-ecto/ecto) changesets.

## Installation

Add `ecto_nested_changeset` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_nested_changeset, "~> 0.2.0"}
  ]
end
```

## Usage

The primary use case of this library is the manipulation of
[Ecto](https://github.com/elixir-ecto/ecto) changesets
used as a source for dynamic, nested forms in
[Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view).

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
git clone https://github.com/woylie/ecto_nested_changeset.git
cd ecto_nested_changeset/example
mix setup
mix phx.server
```

Note that Postgres needs to be running to use the application.

You can access the application at http://localhost:4010.

## Status

This library has a very narrow purpose, which means that even though it is
young, it is unlikely that new functionality is going to be added or that the
API is going to change. Should you miss something, though, don't hesitate to
open an issue. Any issues and problems that may arise will be dealt with
swiftly.
