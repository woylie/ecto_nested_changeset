defmodule Nested.Members.Pet do
  use Ecto.Schema
  import Ecto.Changeset
  alias Nested.Members.Toy

  schema "pets" do
    field :name, :string
    field :owner_id, :id

    has_many :toys, Toy

    timestamps()
  end

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [:name])
    |> cast_assoc(:toys)
    |> validate_required([:name])
  end
end
