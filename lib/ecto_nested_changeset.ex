defmodule EctoNestedChangeset do
  @moduledoc """
  This module defines function for manipulating nested changesets.

  All functions take a path as the second argument. The path is a list of atoms
  (for field names) and integers (for indexes in lists).
  """

  import Ecto.Changeset

  alias Ecto.Association.NotLoaded
  alias Ecto.Changeset

  @doc """
  Appends a value to the field referenced by the path.

  The last path segment must be an atom referencing either a to-many relation
  field or an array field.

  ## Example

      iex> %Owner{pets: [%Pet{}, %Pet{toys: [%Toy{name: "stick"}]}]}
      ...> |> Ecto.Changeset.change()
      ...> |> append_at(changeset, [:pets, 1, :toys], %Toy{name: "ball"})
      ...> |> Ecto.Changeset.apply_changes()
      %Owner{
        pets: [
          %Pet{},
          %Pet{toys: [%Toy{name: "stick"}, %Toy{name: "ball"}]}
        ]
      }
  """
  @spec append_at(Changeset.t(), [atom | non_neg_integer] | atom, any) ::
          Changeset.t()
  def append_at(%Changeset{} = changeset, path, value),
    do: nested_update(:append, changeset, path, value)

  @doc """
  Prepends a value to the field referenced by the path.

  The last path segment must be an atom referencing either a to-many relation
  field or an array field.

  ## Example

      iex> %Owner{pets: [%Pet{}, %Pet{toys: [%Toy{name: "stick"}]}]}
      ...> |> Ecto.Changeset.change()
      ...> |> prepend_at(changeset, [:pets, 1, :toys], %Toy{name: "ball"})
      ...> |> Ecto.Changeset.apply_changes()
      %Owner{
        pets: [
          %Pet{},
          %Pet{toys: [%Toy{name: "ball"}, %Toy{name: "stick"}]}
        ]
      }
  """
  @spec prepend_at(Changeset.t(), [atom | non_neg_integer] | atom, any) ::
          Changeset.t()
  def prepend_at(%Changeset{} = changeset, path, value),
    do: nested_update(:prepend, changeset, path, value)

  @doc """
  Inserts a value into a field at the given position.

  The last path segment must be an integer for the position.

  ## Example

      iex> %Owner{
      ...>   pets: [
      ...>     %Pet{},
      ...>     %Pet{toys: [%Toy{name: "stick"}, %Toy{name: "ball"}]}
      ...>   ]
      ...> }
      ...> |> Ecto.Changeset.change()
      ...> |> insert_at(changeset, [:pets, 1, :toys, 1], %Toy{name: "rope"})
      ...> |> Ecto.Changeset.apply_changes()
      %Owner{
        pets: [
          %Pet{},
          %Pet{
            toys: [
              %Toy{name: "ball"},
              %Toy{name: "rope"},
              %Toy{name: "stick"}
            ]
          }
        ]
      }
  """
  @spec insert_at(Changeset.t(), [atom | non_neg_integer] | atom, any) ::
          Changeset.t()
  def insert_at(%Changeset{} = changeset, path, value),
    do: nested_update(:insert, changeset, path, value)

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

  ## Examples

      iex> %Owner{pets: [%Pet{toys: [%Toy{name: "stick"}, %Toy{name: "ball"}]}]}
      ...> |> Ecto.Changeset.change()
      ...> |> update_at(
      ...>      changeset,
      ...>      [:pets, 1, :toys, 1, :name],
      ...>      &String.upcase/1
      ...>    )
      ...> |> Ecto.Changeset.apply_changes()
      %Owner{
        pets: [
          %Pet{},
          %Pet{
            toys: [
              %Toy{name: "stick"},
              %Toy{name: "BALL"}
            ]
          }
        ]
      }
  """
  @spec update_at(
          Changeset.t(),
          [atom | non_neg_integer] | atom,
          (any -> any)
        ) :: Changeset.t()
  def update_at(%Changeset{} = changeset, path, func) when is_function(func, 1),
    do: nested_update(:update, changeset, path, func)

  @doc """
  Deletes the item at the given path.

  The last path segment is expected to be an integer index.

  Items that are not persisted in the database yet will always be removed from
  the list. For structs that are already persisted in the database, there are
  three different modes.

  - `[mode: {:action, :replace}]` (default) - The item will be wrapped in a
    changeset with the `:replace` action. This only works if an appropriate
    `:on_replace` option is set for the relation in the schema.
  - `[mode: {:action, :delete}]` - The item will be wrapped in a changeset with
    the action set to `:delete`.
  - `[mode: {:flag, field}]` - Puts `true` as a change for the given field.

  The flag option useful for explicitly marking items for deletion in form
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

  ## Examples

      iex> changeset = Ecto.Changeset.change(
             %Owner{pets: [%Pet{name: "George"}, %Pet{name: "Patty"}]}
      ...> )
      iex> delete_at(changeset, [:pets, 1])
      %Ecto.Changeset{
        changes: [
          %Changeset{action: :replace, data: %Post{name: "Patty"}},
          %Changeset{action: :update, data: %Post{name: "George"}},
        ]
      }
      iex> delete_at(changeset, [:pets, 1], mode: {:action, :delete})
      %Ecto.Changeset{
        changes: [
          %Changeset{action: :update, data: %Post{name: "George"}},
          %Changeset{action: :delete, data: %Post{name: "Patty"}},
        ]
      }
      iex> delete_at(changeset, [:pets, 1], mode: {:field, :delete})
      %Ecto.Changeset{
        changes: [
          %Changeset{action: :update, data: %Post{name: "George"}},
          %Changeset{
            action: :update,
            changes: %{delete: true},
            data: %Post{name: "Patty"}
          },
        ]
      }
  """
  @spec delete_at(Changeset.t(), [atom | non_neg_integer] | atom, keyword) ::
          Changeset.t()
  def delete_at(%Changeset{} = changeset, path, opts \\ []) do
    mode = opts[:mode] || {:action, :replace}
    nested_update(:delete, changeset, path, mode)
  end

  @doc """
  Returns a value from a changeset referenced by the path.

  ## Example

      iex> %Owner{pets: [%Pet{}, %Pet{toys: [%Toy{name: "stick"}]}]}
      ...> |> Ecto.Changeset.change()
      ...> |> get_at(changeset, [:pets, 1, :toys])
      [%Toy{name: "stick"}, %Toy{name: "ball"}]
  """
  @spec get_at(Changeset.t(), [atom | non_neg_integer] | atom) :: any()
  def get_at(%Changeset{} = changeset, path) do
    nested_get(:get, changeset, path)
  end

  @doc """
  Moves the value in the to-many relation field or an array field
  at the specified index to the index - 1 position.

  The second to last path segment must be an atom referencing
  either a to-many relation field or an array field.
  The last path segment must be an integer.

  ## Example

      iex> %Owner{pets: [%Pet{}, %Pet{toys: [%Toy{name: "stick"}]}]}
      ...> |> Ecto.Changeset.change()
      ...> |> move_up(changeset, [:pets, 1])
    %Owner{pets: [%Pet{toys: [%Toy{name: "stick"}]}, %Pet{}]}
  """
  @spec move_up(Changeset.t(), [atom | non_neg_integer]) :: any()
  def move_up(%Changeset{} = changeset, path) do
    index = path |> Enum.reverse() |> List.first()
    path = Enum.drop(path, -1)
    nested_update(:move_up, changeset, path, index)
  end

  defp nested_update(operation, changeset, field, value) when is_atom(field),
    do: nested_update(operation, changeset, [field], value)

  defp nested_update(:append, %Changeset{} = changeset, [field], value)
       when is_atom(field) do
    new_value =
      case get_change_or_field(changeset, field) do
        %NotLoaded{} ->
          if Ecto.get_meta(changeset.data, :state) == :built,
            do: [value],
            else: raise(EctoNestedChangeset.NotLoadedError, field: field)

        previous_value ->
          previous_value ++ [value]
      end

    Changeset.put_change(changeset, field, new_value)
  end

  defp nested_update(:append, %{} = data, [field], value) when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, Map.fetch!(data, field) ++ [value])
  end

  defp nested_update(:move_up, %Changeset{} = changeset, [field], index)
       when is_atom(field) do
    list_field = get_change_or_field(changeset, field)
    current_item = Enum.at(list_field, index)

    {above_index, item_above} = find_previous_item(list_field, index - 1)

    list_field
    |> List.replace_at(index, item_above)
    |> List.replace_at(above_index, current_item)
  end

  defp nested_update(:prepend, %Changeset{} = changeset, [field], value)
       when is_atom(field) do
    new_value =
      case get_change_or_field(changeset, field) do
        %NotLoaded{} ->
          if Ecto.get_meta(changeset.data, :state) == :built,
            do: [value],
            else: raise(EctoNestedChangeset.NotLoadedError, field: field)

        previous_value ->
          [value | previous_value]
      end

    Changeset.put_change(changeset, field, new_value)
  end

  defp nested_update(:prepend, %{} = data, [field], value)
       when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, [value | Map.fetch!(data, field)])
  end

  defp nested_update(:insert, items, [index], value)
       when is_list(items) and is_integer(index) do
    List.insert_at(items, index, value)
  end

  defp nested_update(:insert, %Changeset{} = changeset, [field, index], value)
       when is_atom(field) and is_integer(index) do
    new_value =
      case get_change_or_field(changeset, field) do
        %NotLoaded{} ->
          if Ecto.get_meta(changeset.data, :state) == :built,
            do: [value],
            else: raise(EctoNestedChangeset.NotLoadedError, field: field)

        previous_value ->
          List.insert_at(previous_value, index, value)
      end

    Changeset.put_change(changeset, field, new_value)
  end

  defp nested_update(:update, %Changeset{} = changeset, [field], func)
       when is_atom(field) do
    value = get_change_or_field(changeset, field)
    Changeset.put_change(changeset, field, func.(value))
  end

  defp nested_update(:update, %{} = data, [field], func)
       when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, func.(Map.fetch!(data, field)))
  end

  defp nested_update(:update, items, [index], func)
       when is_list(items) and is_integer(index) do
    List.update_at(items, index, &func.(&1))
  end

  defp nested_update(:delete, items, [index], mode)
       when is_list(items) and is_integer(index) do
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
    nested_value = get_change_or_field(changeset, field)

    Changeset.put_change(
      changeset,
      field,
      nested_update(operation, nested_value, rest, value)
    )
  end

  defp nested_update(operation, %{} = data, [field | rest], value)
       when is_atom(field) do
    nested_value = Map.get(data, field)

    data
    |> change()
    |> put_change(field, nested_update(operation, nested_value, rest, value))
  end

  defp nested_update(operation, items, [index | rest], value)
       when is_list(items) and is_integer(index) do
    List.update_at(items, index, fn changeset_or_value ->
      nested_update(operation, changeset_or_value, rest, value)
    end)
  end

  defp nested_get(:get, %Changeset{} = changeset, [field])
       when is_atom(field) do
    Changeset.get_field(changeset, field)
  end

  defp nested_get(:get, %{} = data, [field])
       when is_atom(field) do
    Map.get(data, field)
  end

  defp nested_get(:get, items, [index])
       when is_list(items) and is_integer(index) do
    Enum.at(items, index)
  end

  defp nested_get(operation, %Changeset{} = changeset, [field | rest])
       when is_atom(field) do
    nested_value = get_change_or_field(changeset, field)
    nested_get(operation, nested_value, rest)
  end

  defp nested_get(operation, %{} = data, [field | rest])
       when is_atom(field) do
    nested_value = Map.get(data, field)
    nested_get(operation, nested_value, rest)
  end

  defp nested_get(operation, items, [index | rest])
       when is_list(items) and is_integer(index) do
    nested_value = Enum.at(items, index)
    nested_get(operation, nested_value, rest)
  end

  defp get_change_or_field(%Changeset{} = changeset, field) do
    case Map.fetch(changeset.changes, field) do
      {:ok, value} -> value
      :error -> Map.get(changeset.data, field)
    end
  end

  defp find_previous_item(changeset_list_field, index)
       when is_list(changeset_list_field) do
    current_item = Enum.at(changeset_list_field, index)

    if current_item |> change() |> Changeset.get_change(:delete) do
      find_previous_item(changeset_list_field, index - 1)
    else
      {index, current_item}
    end
  end
end
