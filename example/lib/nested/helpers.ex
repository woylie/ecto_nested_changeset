defmodule Nested.Helpers do
  import Ecto.Changeset
  alias Ecto.Changeset

  def maybe_mark_for_deletion(%Changeset{} = changeset) do
    if get_change(changeset, :delete) do
      Map.put(changeset, :action, :delete)
    else
      changeset
    end
  end
end
