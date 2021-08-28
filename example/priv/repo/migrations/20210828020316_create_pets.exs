defmodule Nested.Repo.Migrations.CreatePets do
  use Ecto.Migration

  def change do
    create table(:pets) do
      add :name, :string
      add :owner_id, references(:owners, on_delete: :delete_all)

      timestamps()
    end

    create index(:pets, [:owner_id])
  end
end
