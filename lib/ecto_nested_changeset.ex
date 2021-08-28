defmodule EctoNestedChangeset do
  @moduledoc """
  This module defines function for manipulating nested changesets.
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @doc """
  Appends a value to the field referenced by the path.

  The last path segment must be an atom referencing either a to-many relation
  field or an array field.
  """
  @spec append_at(Changeset.t(), [atom | non_neg_integer] | atom, any) ::
          Changeset.t()
  def append_at(%Changeset{} = changeset, path, value),
    do: nested_update(:append, changeset, path, value)

  @doc """
  Prepends a value to the field referenced by the path.

  The last path segment must be an atom referencing either a to-many relation
  field or an array field.
  """
  @spec prepend_at(Changeset.t(), [atom | non_neg_integer] | atom, any) ::
          Changeset.t()
  def prepend_at(%Changeset{} = changeset, path, value),
    do: nested_update(:prepend, changeset, path, value)

  @doc """
  Inserts a value into a field at the given position.

  The last path segment must be an integer for the position.
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
  either to the change or to existing value. The values will not be unwrapped,
  which means that the update function passed as the last parameter must
  potentially handle either changesets or raw values, depending on the path.
  """
  @spec update_at(Changeset.t(), [atom | non_neg_integer] | atom, fun) ::
          Changeset.t()
  def update_at(%Changeset{} = changeset, path, func) when is_function(func, 1),
    do: nested_update(:update, changeset, path, func)

  @doc """
  Deletes the item at the given path.

  The last path segment is expected to be an integer index.

  Items that are not persisted in the database yet will always be removed from
  the list. For structs that are already persisted in the database, there are
  three different modes.

  - `[mode: :replace]` (default) - The item will be wrapped in a changeset with
    the `:replace` action. This only works if an appropriate `:on_replace`
    option is set for the relation in the schema.
  - `[mode: :delete]` - The item will be wrapped in a changeset with the action
    set to `:delete`.
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
  """
  @spec delete_at(Changeset.t(), [atom | non_neg_integer] | atom, keyword) ::
          Changeset.t()
  def delete_at(%Changeset{} = changeset, path, opts \\ []),
    do: nested_update(:delete, changeset, path, opts)

  defp nested_update(operation, changeset, field, value) when is_atom(field),
    do: nested_update(operation, changeset, [field], value)

  defp nested_update(:append, %Changeset{} = changeset, [field], value)
       when is_atom(field) do
    Changeset.put_change(
      changeset,
      field,
      get_change_or_field(changeset, field) ++ [value]
    )
  end

  defp nested_update(:append, %{} = data, [field], value) when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, Map.fetch!(data, field) ++ [value])
  end

  defp nested_update(:prepend, %Changeset{} = changeset, [field], value)
       when is_atom(field) do
    Changeset.put_change(
      changeset,
      field,
      [value | get_change_or_field(changeset, field)]
    )
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

  defp nested_update(:delete, items, [index], opts)
       when is_list(items) and is_integer(index) do
    case Enum.at(items, index) do
      %Changeset{action: :insert} ->
        List.delete_at(items, index)

      %{} = item ->
        case opts[:mode] || :replace do
          :delete ->
            List.replace_at(
              items,
              index,
              item |> change() |> Map.put(:action, :delete)
            )

          :replace ->
            List.delete_at(items, index)

          {:flag, field} ->
            List.replace_at(
              items,
              index,
              item |> change() |> put_change(field, true)
            )
        end

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

  defp get_change_or_field(%Changeset{} = changeset, field) do
    case Map.fetch(changeset.changes, field) do
      {:ok, value} -> value
      :error -> Map.get(changeset.data, field)
    end
  end
end
