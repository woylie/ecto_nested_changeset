defmodule Nested.Members.Toy do
  @moduledoc """
  Schema for toys, which are owned by pets.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Nested.Helpers

  schema "toys" do
    field :name, :string
    field :pet_id, :id
    field :delete, :boolean, virtual: true, default: false

    timestamps()
  end

  @doc false
  def changeset(toy, attrs) do
    toy
    |> cast(attrs, [:name, :delete])
    |> validate_required([:name])
    |> Helpers.maybe_mark_for_deletion()
  end
end
