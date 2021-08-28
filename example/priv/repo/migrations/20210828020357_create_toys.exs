defmodule Nested.Repo.Migrations.CreateToys do
  use Ecto.Migration

  def change do
    create table(:toys) do
      add :name, :string
      add :pet_id, references(:pets, on_delete: :nothing)

      timestamps()
    end

    create index(:toys, [:pet_id])
  end
end
