defmodule Nested.Members.Toy do
  use Ecto.Schema
  import Ecto.Changeset

  schema "toys" do
    field :name, :string
    field :pet_id, :id

    timestamps()
  end

  @doc false
  def changeset(toy, attrs) do
    toy
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
