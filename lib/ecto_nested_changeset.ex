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
    do: nested_update(:append, changeset, validate_path!(path), value)

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
    do: nested_update(:prepend, changeset, validate_path!(path), value)

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
    do: nested_update(:insert, changeset, validate_path!(path), value)

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
    do: nested_update(:update, changeset, validate_path!(path), func)

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
  def delete_at(%Changeset{} = changeset, path, opts \\ []),
    do:
      nested_update(
        :delete,
        changeset,
        validate_path!(path),
        mode_from_opts!(opts)
      )

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
