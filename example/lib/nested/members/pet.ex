defmodule Nested.Members.Pet do
  @moduledoc """
  Schema for pets, which are owned by owners.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Nested.Helpers
  alias Nested.Members.Toy

  schema "pets" do
    field :name, :string
    field :owner_id, :id
    field :delete, :boolean, virtual: true, default: false

    has_many :toys, Toy

    timestamps()
  end

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [:name, :delete])
    |> cast_assoc(:toys)
    |> validate_required([:name])
    |> Helpers.maybe_mark_for_deletion()
  end
end
