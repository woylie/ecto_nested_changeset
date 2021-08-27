defmodule EctoNestedChangeset do
  @moduledoc """
  Documentation for `EctoNestedChangeset`.
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @spec append_at(Changeset.t(), [atom | non_neg_integer] | atom, any) ::
          Changeset.t()
  def append_at(changeset, path, value),
    do: nested_update(changeset, path, value, :append)

  @spec prepend_at(Changeset.t(), [atom | non_neg_integer] | atom, any) ::
          Changeset.t()
  def prepend_at(changeset, path, value),
    do: nested_update(changeset, path, value, :prepend)

  @spec insert_at(Changeset.t(), [atom | non_neg_integer] | atom, any) ::
          Changeset.t()
  def insert_at(changeset, path, value),
    do: nested_update(changeset, path, value, :insert)

  @spec delete_at(Changeset.t(), [atom | non_neg_integer] | atom) ::
          Changeset.t()
  def delete_at(changeset, path),
    do: nested_update(changeset, path, nil, :delete)

  defp nested_update(changeset, field, value, operation) when is_atom(field),
    do: nested_update(changeset, [field], value, operation)

  defp nested_update(%Changeset{} = changeset, [field], value, :append)
       when is_atom(field) do
    Changeset.put_change(
      changeset,
      field,
      get_change_or_field(changeset, field) ++ [value]
    )
  end

  defp nested_update(%{} = data, [field], value, :append) when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, Map.fetch!(data, field) ++ [value])
  end

  defp nested_update(%Changeset{} = changeset, [field], value, :prepend)
       when is_atom(field) do
    Changeset.put_change(
      changeset,
      field,
      [value | get_change_or_field(changeset, field)]
    )
  end

  defp nested_update(%{} = data, [field], value, :prepend)
       when is_atom(field) do
    data
    |> Changeset.change()
    |> Changeset.put_change(field, [value | Map.fetch!(data, field)])
  end

  defp nested_update(items, [index], value, :insert)
       when is_list(items) and is_integer(index) do
    List.insert_at(items, index, value)
  end

  defp nested_update(items, [index], nil, :delete)
       when is_list(items) and is_integer(index) do
    List.delete_at(items, index)
  end

  defp nested_update(%Changeset{} = changeset, [field | rest], value, operation)
       when is_atom(field) do
    nested_value = get_change_or_field(changeset, field)

    Changeset.put_change(
      changeset,
      field,
      nested_update(nested_value, rest, value, operation)
    )
  end

  defp nested_update(%{} = data, [field | rest], value, operation)
       when is_atom(field) do
    nested_value = Map.get(data, field)

    data
    |> change()
    |> put_change(field, nested_update(nested_value, rest, value, operation))
  end

  defp nested_update(items, [index | rest], value, operation)
       when is_list(items) and is_integer(index) do
    List.update_at(items, index, fn changeset_or_value ->
      nested_update(changeset_or_value, rest, value, operation)
    end)
  end

  defp get_change_or_field(%Changeset{} = changeset, field) do
    case Map.fetch(changeset.changes, field) do
      {:ok, value} -> value
      :error -> Map.get(changeset.data, field)
    end
  end

  defp get_change_or_field(%{} = data, field) do
    Map.get(data, field)
  end
end
