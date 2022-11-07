defmodule Nested.MembersTest do
  use Nested.DataCase

  alias Nested.Members

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
end
