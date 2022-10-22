defmodule Nested.MembersTest do
  use Nested.DataCase

  alias Nested.Members
  alias Nested.Members.Pet

  describe "owners" do
    alias Nested.Members.Owner

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def owner_fixture(attrs \\ %{}) do
      {:ok, owner} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Members.create_owner()

      Repo.preload(owner, pets: [:toys])
    end

    test "list_owners/0 returns all owners" do
      owner = owner_fixture()
      assert Members.list_owners() == [owner]
    end

    test "get_owner!/1 returns the owner with given id" do
      owner = owner_fixture()
      assert Members.get_owner!(owner.id) == owner
    end

    test "create_owner/1 with valid data creates a owner" do
      assert {:ok, %Owner{} = owner} = Members.create_owner(@valid_attrs)
      assert owner.name == "some name"
    end

    test "create_owner/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Members.create_owner(@invalid_attrs)
    end

    test "update_owner/2 with valid data updates the owner" do
      owner = owner_fixture()

      assert {:ok, %Owner{} = owner} =
               Members.update_owner(owner, @update_attrs)

      assert owner.name == "some updated name"
    end

    @tag :this
    test "flip flop existing struct" do
      {:ok, owner} =
        Members.create_owner(%{
          name: "jack",
          pets: [%{name: "holly"}, %{name: "judy"}]
        })

      owner =
        owner
        |> Ecto.Changeset.change()
        |> EctoNestedChangeset.update_at([:pets, 1, :name], fn _ ->
          "holly"
        end)
        |> EctoNestedChangeset.update_at([:pets, 0, :name], fn _ ->
          "judy"
        end)
        |> EctoNestedChangeset.update_at([:pets, 1, :name], fn _ ->
          "holly"
        end)
        |> EctoNestedChangeset.update_at([:pets, 0, :name], fn _ ->
          "judy"
        end)
        |> EctoNestedChangeset.update_at([:pets, 1, :name], fn _ ->
          "holly"
        end)
        |> EctoNestedChangeset.update_at([:pets, 0, :name], fn _ ->
          "judy"
        end)

      Nested.Repo.update(owner)
      |> IO.inspect()

      # assert {:ok, %Owner{} = owner} =
      #          Members.update_owner(owner, @update_attrs)
    end

    test "update_owner/2 with invalid data returns error changeset" do
      owner = owner_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Members.update_owner(owner, @invalid_attrs)

      assert owner == Members.get_owner!(owner.id)
    end

    test "delete_owner/1 deletes the owner" do
      owner = owner_fixture()
      assert {:ok, %Owner{}} = Members.delete_owner(owner)
      assert_raise Ecto.NoResultsError, fn -> Members.get_owner!(owner.id) end
    end

    test "change_owner/1 returns a owner changeset" do
      owner = owner_fixture()
      assert %Ecto.Changeset{} = Members.change_owner(owner)
    end
  end

  describe "pets" do
    alias Nested.Members.Pet

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def pet_fixture(attrs \\ %{}) do
      {:ok, pet} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Members.create_pet()

      pet
    end

    test "list_pets/0 returns all pets" do
      pet = pet_fixture()
      assert Members.list_pets() == [pet]
    end

    test "get_pet!/1 returns the pet with given id" do
      pet = pet_fixture()
      assert Members.get_pet!(pet.id) == pet
    end

    test "create_pet/1 with valid data creates a pet" do
      assert {:ok, %Pet{} = pet} = Members.create_pet(@valid_attrs)
      assert pet.name == "some name"
    end

    test "create_pet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Members.create_pet(@invalid_attrs)
    end

    test "update_pet/2 with valid data updates the pet" do
      pet = pet_fixture()
      assert {:ok, %Pet{} = pet} = Members.update_pet(pet, @update_attrs)
      assert pet.name == "some updated name"
    end

    test "update_pet/2 with invalid data returns error changeset" do
      pet = pet_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Members.update_pet(pet, @invalid_attrs)

      assert pet == Members.get_pet!(pet.id)
    end

    test "delete_pet/1 deletes the pet" do
      pet = pet_fixture()
      assert {:ok, %Pet{}} = Members.delete_pet(pet)
      assert_raise Ecto.NoResultsError, fn -> Members.get_pet!(pet.id) end
    end

    test "change_pet/1 returns a pet changeset" do
      pet = pet_fixture()
      assert %Ecto.Changeset{} = Members.change_pet(pet)
    end
  end

  describe "toys" do
    alias Nested.Members.Toy

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def toy_fixture(attrs \\ %{}) do
      {:ok, toy} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Members.create_toy()

      toy
    end

    test "list_toys/0 returns all toys" do
      toy = toy_fixture()
      assert Members.list_toys() == [toy]
    end

    test "get_toy!/1 returns the toy with given id" do
      toy = toy_fixture()
      assert Members.get_toy!(toy.id) == toy
    end

    test "create_toy/1 with valid data creates a toy" do
      assert {:ok, %Toy{} = toy} = Members.create_toy(@valid_attrs)
      assert toy.name == "some name"
    end

    test "create_toy/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Members.create_toy(@invalid_attrs)
    end

    test "update_toy/2 with valid data updates the toy" do
      toy = toy_fixture()
      assert {:ok, %Toy{} = toy} = Members.update_toy(toy, @update_attrs)
      assert toy.name == "some updated name"
    end

    test "update_toy/2 with invalid data returns error changeset" do
      toy = toy_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Members.update_toy(toy, @invalid_attrs)

      assert toy == Members.get_toy!(toy.id)
    end

    test "delete_toy/1 deletes the toy" do
      toy = toy_fixture()
      assert {:ok, %Toy{}} = Members.delete_toy(toy)
      assert_raise Ecto.NoResultsError, fn -> Members.get_toy!(toy.id) end
    end

    test "change_toy/1 returns a toy changeset" do
      toy = toy_fixture()
      assert %Ecto.Changeset{} = Members.change_toy(toy)
    end
  end
end
