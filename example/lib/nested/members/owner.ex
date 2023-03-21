defmodule Nested.Members.Owner do
  @moduledoc """
  Schema for pet owners.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Nested.Members.Pet

  schema "owners" do
    field :name, :string

    has_many :pets, Pet

    timestamps()
  end

  @doc false
  def changeset(owner, attrs) do
    owner
    |> cast(attrs, [:name])
    |> cast_assoc(:pets)
    |> validate_required([:name])
  end
end
