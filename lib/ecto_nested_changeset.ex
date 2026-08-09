defmodule EctoNestedChangeset do
  @moduledoc """
  This module defines functions for manipulating nested changesets.

  All functions take a path as the second argument. The path is a list of atoms
  (for field names) and non-negative integers (for indexes in lists). A bare
  atom is accepted as a shorthand for a single-segment path. Every function
  validates the path and raises an `ArgumentError` naming the offending segment
  and its position if it is empty or holds anything else.

  `append_at/3`, `prepend_at/3`, `insert_at/3` and `update_at/3` raise
  `EctoNestedChangeset.NotLoadedError` if the path passes through a relation
  field that is not loaded on a struct that is already persisted, at any depth.
  If the struct was never persisted, the relation reads as an empty list
  instead, since there is nothing to preload yet. `get_at/2` does not raise: it
  returns `nil` for a relation that is not loaded.

  ## Schemas used in the examples

  The examples in this module operate on these schemas.

      defmodule Category do
        use Ecto.Schema

        schema "categories" do
          has_many :posts, Post, on_replace: :delete
        end
      end

      defmodule Post do
        use Ecto.Schema

        schema "posts" do
          field :delete, :boolean, virtual: true, default: false
          field :title, :string
          field :tags, {:array, :string}, default: []
          belongs_to :category, Category
          has_many :comments, Comment
        end
      end

      defmodule Comment do
        use Ecto.Schema

        schema "comments" do
          field :body, :string
          belongs_to :post, Post
        end
      end
  """

  import Ecto.Changeset

  alias Ecto.Association.NotLoaded
  alias Ecto.Changeset

  @typedoc """
  Points at a field or a list item within a changeset.

  A path is a list of atoms for field names and non-negative integers for
  indexes in lists. A bare atom is a shorthand for a single-segment path.

      [:posts, 0, :comments]
      :posts
  """
  @typedoc since: "1.1.0"
  @type path :: [atom | non_neg_integer] | atom

  @doc """
  Appends a value to the field referenced by the path.

  The last path segment must be an atom referencing either a to-many relation
  field or an array field.

  ## Example

      iex> %Category{
      ...>   posts: [
      ...>     %Post{id: 1, title: "first", comments: []},
      ...>     %Post{id: 2, title: "second", comments: [%Comment{body: "one"}]}
      ...>   ]
      ...> }
      ...> |> Ecto.Changeset.change()
      ...> |> append_at([:posts, 1, :comments], %Comment{body: "two"})
      ...> |> Ecto.Changeset.apply_changes()
      ...> |> Map.fetch!(:posts)
      ...> |> Enum.map(fn post -> Enum.map(post.comments, & &1.body) end)
      [[], ["one", "two"]]
  """
  @doc since: "0.1.0"
  @spec append_at(Changeset.t(), path, any) :: Changeset.t()
  def append_at(%Changeset{} = changeset, path, value) do
    path = validate_path!(path)
    %Changeset{} = nested_update(:append, changeset, path, value)
  end

  @doc """
  Prepends a value to the field referenced by the path.

  The last path segment must be an atom referencing either a to-many relation
  field or an array field.

  ## Example

      iex> %Category{
      ...>   posts: [
      ...>     %Post{id: 1, title: "first", comments: []},
      ...>     %Post{id: 2, title: "second", comments: [%Comment{body: "one"}]}
      ...>   ]
      ...> }
      ...> |> Ecto.Changeset.change()
      ...> |> prepend_at([:posts, 1, :comments], %Comment{body: "two"})
      ...> |> Ecto.Changeset.apply_changes()
      ...> |> Map.fetch!(:posts)
      ...> |> Enum.map(fn post -> Enum.map(post.comments, & &1.body) end)
      [[], ["two", "one"]]
  """
  @doc since: "0.1.0"
  @spec prepend_at(Changeset.t(), path, any) :: Changeset.t()
  def prepend_at(%Changeset{} = changeset, path, value) do
    path = validate_path!(path)
    %Changeset{} = nested_update(:prepend, changeset, path, value)
  end

  @doc """
  Inserts a value into a field at the given position.

  The last path segment must be an integer for the position.

  ## Example

      iex> %Category{
      ...>   posts: [
      ...>     %Post{id: 1, title: "first"},
      ...>     %Post{id: 2, title: "third"}
      ...>   ]
      ...> }
      ...> |> Ecto.Changeset.change()
      ...> |> insert_at([:posts, 1], %Post{title: "second"})
      ...> |> Ecto.Changeset.apply_changes()
      ...> |> Map.fetch!(:posts)
      ...> |> Enum.map(& &1.title)
      ["first", "second", "third"]
  """
  @doc since: "0.1.0"
  @spec insert_at(Changeset.t(), path, any) :: Changeset.t()
  def insert_at(%Changeset{} = changeset, path, value) do
    path = validate_path!(path)
    %Changeset{} = nested_update(:insert, changeset, path, value)
  end

  @doc """
  Updates the value in the changeset at the given position with the given update
  function.

  The path may lead to any field, including arrays and relation fields. Unlike
  `Ecto.Changeset.update_change/3`, the update function is always applied,
  either to the change or to existing value.

  If the path points to a field with a simple type, the update function will
  receive the raw value of the field. However, if the path points to the field
  of a *-to-many relation, the list values will not be unwrapped, which means
  that the update function has to handle a list of changesets.

  ## Example

      iex> %Category{
      ...>   posts: [
      ...>     %Post{id: 1, title: "first"},
      ...>     %Post{id: 2, title: "second"}
      ...>   ]
      ...> }
      ...> |> Ecto.Changeset.change()
      ...> |> update_at([:posts, 1, :title], &String.upcase/1)
      ...> |> Ecto.Changeset.apply_changes()
      ...> |> Map.fetch!(:posts)
      ...> |> Enum.map(& &1.title)
      ["first", "SECOND"]
  """
  @doc since: "0.1.0"
  @spec update_at(Changeset.t(), path, (any -> any)) :: Changeset.t()
  def update_at(%Changeset{} = changeset, path, func)
      when is_function(func, 1) do
    path = validate_path!(path)
    %Changeset{} = nested_update(:update, changeset, path, func)
  end

  @doc """
  Deletes the item at the given path.

  The last path segment is expected to be an integer index.

  Items added with `append_at/3`, `prepend_at/3` or `insert_at/3` and not
  persisted in the database yet will always be removed from the list, whatever
  the mode. For structs that are already persisted in the database, there are
  three different modes.

  - `[mode: {:action, :replace}]` (default) - The item will be wrapped in a
    changeset with the `:replace` action. This only works if an appropriate
    `:on_replace` option is set for the relation in the schema.
  - `[mode: {:action, :delete}]` - The item will be wrapped in a changeset with
    the action set to `:delete`.
  - `[mode: {:flag, field}]` - Puts `true` as a change for the given field.

  An unpersisted struct that the caller put into the parent's `:data` rather
  than its `:changes` is neither of those cases. It is treated like a persisted
  struct, and `c:Ecto.Repo.update/2` then raises
  `Ecto.NoPrimaryKeyValueError`. Removing it from the list instead would not
  help, since Ecto reconciles the relation against `:data` and tries to delete
  it there. Add unpersisted items with `append_at/3`, `prepend_at/3` or
  `insert_at/3`, so that they end up in the changes.

  The flag option is useful for explicitly marking items for deletion in form
  parameters. In this case, you would configure a virtual field on the schema
  and set the changeset action to `:delete` in the changeset function in case
  the value is set to `true`.

      schema "pets" do
        field :name, :string
        field :delete, :boolean, virtual: true, default: false
      end

      def changeset(pet, attrs) do
        pet
        |> cast(attrs, [:name, :delete])
        |> validate_required([:name])
        |> maybe_mark_for_deletion()
      end

      def maybe_mark_for_deletion(%Ecto.Changeset{} = changeset) do
        if Ecto.Changeset.get_change(changeset, :delete),
          do: Map.put(changeset, :action, :delete),
          else: changeset
      end

  An unknown option key or an unknown `:mode` value raises an `ArgumentError`.

  ## Examples

      iex> changeset =
      ...>   Ecto.Changeset.change(%Category{
      ...>     posts: [
      ...>       %Post{id: 1, title: "first"},
      ...>       %Post{id: 2, title: "second"}
      ...>     ]
      ...>   })
      iex> changeset
      ...> |> delete_at([:posts, 1])
      ...> |> Map.fetch!(:changes)
      ...> |> Map.fetch!(:posts)
      ...> |> Enum.map(&{&1.action, &1.data.title})
      [replace: "second", update: "first"]
      iex> changeset
      ...> |> delete_at([:posts, 1], mode: {:action, :delete})
      ...> |> Map.fetch!(:changes)
      ...> |> Map.fetch!(:posts)
      ...> |> Enum.map(&{&1.action, &1.data.title})
      [update: "first", delete: "second"]
      iex> changeset
      ...> |> delete_at([:posts, 1], mode: {:flag, :delete})
      ...> |> Map.fetch!(:changes)
      ...> |> Map.fetch!(:posts)
      ...> |> Enum.map(&{&1.data.title, &1.changes})
      [{"first", %{}}, {"second", %{delete: true}}]
  """
  @doc since: "0.1.0"
  @spec delete_at(Changeset.t(), path, keyword) :: Changeset.t()
  def delete_at(%Changeset{} = changeset, path, opts \\ []) do
    path = validate_path!(path)
    mode = mode_from_opts!(opts)
    %Changeset{} = nested_update(:delete, changeset, path, mode)
  end

  @doc """
  Returns a value from a changeset referenced by the path.

  ## Example

      iex> %Category{
      ...>   posts: [%Post{title: "first"}, %Post{title: "second"}]
      ...> }
      ...> |> Ecto.Changeset.change()
      ...> |> get_at([:posts, 1, :title])
      "second"
  """
  @doc since: "0.2.0"
  @spec get_at(Changeset.t(), path) :: any()
  def get_at(%Changeset{} = changeset, path) do
    nested_get(:get, changeset, validate_path!(path))
  end

  defp validate_path!(field) when is_atom(field), do: [field]

  defp validate_path!([_ | _] = path) do
    case Enum.find_index(path, &(not valid_segment?(&1))) do
      nil ->
        path

      index ->
        raise ArgumentError, """
        invalid path segment passed to EctoNestedChangeset

        Expected an atom for a field name, or a non-negative integer for a list
        index.

        Got, at position #{index}:

            #{inspect(Enum.at(path, index))}
        """
    end
  end

  defp validate_path!(path) do
    raise ArgumentError, """
    invalid path passed to EctoNestedChangeset

    Expected an atom, or a non-empty list of atoms and non-negative integers.

    Got:

        #{inspect(path)}
    """
  end

  defp valid_segment?(segment) when is_atom(segment), do: true

  defp valid_segment?(segment) when is_integer(segment) and segment >= 0,
    do: true

  defp valid_segment?(_segment), do: false

  defp mode_from_opts!(opts) do
    opts
    |> Keyword.validate!(mode: {:action, :replace})
    |> Keyword.fetch!(:mode)
    |> validate_mode!()
  end

  defp validate_mode!({:action, action} = mode)
       when action in [:replace, :delete],
       do: mode

  defp validate_mode!({:flag, field} = mode) when is_atom(field), do: mode

  defp validate_mode!(mode) do
    raise ArgumentError, """
    invalid :mode option passed to EctoNestedChangeset.delete_at/3

    Expected one of:

        {:action, :replace}
        {:action, :delete}
        {:flag, field}

    Got:

        #{inspect(mode)}
    """
  end

  defp nested_update(:append, %Changeset{} = changeset, [field], value)
       when is_atom(field) do
    Changeset.put_change(
      changeset,
      field,
      fetch_loaded!(changeset, field) ++ [value]
    )
  end

  defp nested_update(:append, %{} = data, [field], value) when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, fetch_loaded!(data, field) ++ [value])
  end

  defp nested_update(:prepend, %Changeset{} = changeset, [field], value)
       when is_atom(field) do
    Changeset.put_change(changeset, field, [
      value | fetch_loaded!(changeset, field)
    ])
  end

  defp nested_update(:prepend, %{} = data, [field], value)
       when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, [value | fetch_loaded!(data, field)])
  end

  defp nested_update(:insert, items, [index], value)
       when is_list(items) and is_integer(index) and index >= 0 do
    List.insert_at(items, index, value)
  end

  defp nested_update(:insert, %Changeset{} = changeset, [field, index], value)
       when is_atom(field) and is_integer(index) and index >= 0 do
    new_value = List.insert_at(fetch_loaded!(changeset, field), index, value)
    Changeset.put_change(changeset, field, new_value)
  end

  defp nested_update(:update, %Changeset{} = changeset, [field], func)
       when is_atom(field) do
    Changeset.put_change(
      changeset,
      field,
      func.(fetch_loaded!(changeset, field))
    )
  end

  defp nested_update(:update, %{} = data, [field], func)
       when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, func.(fetch_loaded!(data, field)))
  end

  defp nested_update(:update, items, [index], func)
       when is_list(items) and is_integer(index) and index >= 0 do
    List.update_at(items, index, &func.(&1))
  end

  defp nested_update(:delete, items, [index], mode)
       when is_list(items) and is_integer(index) and index >= 0 do
    case {Enum.at(items, index), mode} do
      {%Changeset{action: :insert}, _} ->
        List.delete_at(items, index)

      {%{} = item, {:action, :delete}} ->
        List.replace_at(
          items,
          index,
          item |> change() |> Map.put(:action, :delete)
        )

      {%{}, {:action, :replace}} ->
        List.delete_at(items, index)

      {%{} = item, {:flag, field}} when is_atom(field) ->
        List.replace_at(
          items,
          index,
          item |> change() |> put_change(field, true)
        )

      _item ->
        List.delete_at(items, index)
    end
  end

  defp nested_update(operation, %Changeset{} = changeset, [field | rest], value)
       when is_atom(field) do
    nested_value = fetch_loaded!(changeset, field)

    Changeset.put_change(
      changeset,
      field,
      nested_update(operation, nested_value, rest, value)
    )
  end

  defp nested_update(operation, %{} = data, [field | rest], value)
       when is_atom(field) do
    nested_value = fetch_loaded!(data, field)

    data
    |> change()
    |> put_change(field, nested_update(operation, nested_value, rest, value))
  end

  defp nested_update(operation, items, [index | rest], value)
       when is_list(items) and is_integer(index) and index >= 0 do
    List.update_at(items, index, fn changeset_or_value ->
      nested_update(operation, changeset_or_value, rest, value)
    end)
  end

  defp nested_get(:get, %Changeset{} = changeset, [field])
       when is_atom(field) do
    if unloaded?(get_change_or_field(changeset, field), changeset.data),
      do: nil,
      else: Changeset.get_field(changeset, field)
  end

  defp nested_get(:get, %{} = data, [field])
       when is_atom(field) do
    data |> Map.get(field) |> nilify_not_loaded()
  end

  defp nested_get(:get, items, [index])
       when is_list(items) and is_integer(index) and index >= 0 do
    Enum.at(items, index)
  end

  defp nested_get(operation, %Changeset{} = changeset, [field | rest])
       when is_atom(field) do
    case get_change_or_field(changeset, field) do
      %NotLoaded{} -> nil
      nested_value -> nested_get(operation, nested_value, rest)
    end
  end

  defp nested_get(operation, %{} = data, [field | rest])
       when is_atom(field) do
    case Map.get(data, field) do
      %NotLoaded{} -> nil
      nested_value -> nested_get(operation, nested_value, rest)
    end
  end

  defp nested_get(operation, items, [index | rest])
       when is_list(items) and is_integer(index) and index >= 0 do
    nested_value = Enum.at(items, index)
    nested_get(operation, nested_value, rest)
  end

  defp get_change_or_field(%Changeset{} = changeset, field) do
    case Map.fetch(changeset.changes, field) do
      {:ok, value} -> value
      :error -> Map.get(changeset.data, field)
    end
  end

  defp fetch_loaded!(%Changeset{} = changeset, field) do
    changeset
    |> get_change_or_field(field)
    |> loaded!(changeset.data, field)
  end

  defp fetch_loaded!(%{} = data, field) do
    data
    |> Map.fetch!(field)
    |> loaded!(data, field)
  end

  defp loaded!(%NotLoaded{}, data, field) do
    if Ecto.get_meta(data, :state) == :built,
      do: [],
      else: raise(EctoNestedChangeset.NotLoadedError, field: field)
  end

  defp loaded!(value, _data, _field), do: value

  defp nilify_not_loaded(%NotLoaded{}), do: nil
  defp nilify_not_loaded(value), do: value

  defp unloaded?(%NotLoaded{}, data), do: Ecto.get_meta(data, :state) != :built
  defp unloaded?(_value, _data), do: false
end
