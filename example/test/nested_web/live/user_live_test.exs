defmodule NestedWeb.OwnerLiveTest do
  use NestedWeb.ConnCase

  import Nested.MembersFixtures
  import Phoenix.LiveViewTest

  alias Nested.Members.Pet
  alias Nested.Members.Toy
  alias Nested.Repo

  @create_attrs %{
    name: "some name",
    pets: [%{name: "George", toys: [%{name: "ball"}]}]
  }
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_owner(_) do
    owner = owner_fixture(@create_attrs)
    %{owner: owner}
  end

  describe "Index" do
    setup [:create_owner]

    test "lists all owners", %{conn: conn, owner: owner} do
      {:ok, _index_live, html} = live(conn, ~p"/owners")

      assert html =~ "Listing Owners"
      assert html =~ owner.name
    end

    test "saves new owner", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/owners")

      assert index_live |> element("a", "New Owner") |> render_click() =~
               "New Owner"

      assert_patch(index_live, ~p"/owners/new")

      assert index_live
             |> form("#owner-form", owner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#owner-form", owner: %{name: "Lizzy"})
             |> render_submit()

      assert_patch(index_live, ~p"/owners")

      html = render(index_live)
      assert html =~ "Owner created successfully"
      assert html =~ "some name"
    end

    test "adds and removes pet and toy inputs", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/owners/new")

      new_live
      |> element("a", "add pet")
      |> render_click()

      assert new_live
             |> element("input#owner_pets_0_name")
             |> has_element?()

      new_live
      |> element("a", "add pet")
      |> render_click()

      assert new_live
             |> element("input#owner_pets_1_name")
             |> has_element?()

      new_live
      |> element(~s(a[phx-value-pet-index="1"]"), "add toy")
      |> render_click()

      assert new_live
             |> element("input#owner_pets_1_toys_0_name")
             |> has_element?()

      new_live
      |> element(~s(a[phx-value-pet-index="0"]), "add toy")
      |> render_click()

      assert new_live
             |> element("input#owner_pets_0_toys_0_name")
             |> has_element?()

      new_live
      |> element(
        ~s(a[phx-click="remove-pet"][phx-value-pet-index="0"]),
        "remove"
      )
      |> render_click()

      assert new_live
             |> element("input#owner_pets_0_name")
             |> has_element?()

      refute new_live
             |> element("input#owner_pets_1_name")
             |> has_element?()

      refute new_live
             |> element("input#owner_pets_1_toys_0_name")
             |> has_element?()

      refute new_live
             |> element("input#owner_pets_1_toys_1_name")
             |> has_element?()

      new_live
      |> element(
        ~s(a[phx-click="remove-toy"][phx-value-pet-index="0"][phx-value-toy-index="0"]),
        "remove"
      )
      |> render_click()

      refute new_live
             |> element("input#owner_pets_0_toys_1_name")
             |> has_element?()
    end

    test "updates owner in listing", %{conn: conn, owner: owner} do
      {:ok, index_live, _html} = live(conn, ~p"/owners")

      assert index_live
             |> element("#owners-#{owner.id} a", "Edit")
             |> render_click() =~
               "Edit Owner"

      assert_patch(index_live, ~p"/owners/#{owner}/edit")

      assert index_live
             |> form("#owner-form", owner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#owner-form", owner: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/owners")

      html = render(index_live)
      assert html =~ "Owner updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes owner in listing", %{conn: conn, owner: owner} do
      {:ok, index_live, _html} = live(conn, ~p"/owners")

      assert index_live
             |> element("#owners-#{owner.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#owners-#{owner.id}")
    end
  end

  describe "Show" do
    setup [:create_owner]

    test "displays owner", %{conn: conn, owner: owner} do
      {:ok, _show_live, html} = live(conn, ~p"/owners/#{owner}")

      assert html =~ "Show Owner"
      assert html =~ owner.name
    end

    test "updates owner within modal", %{conn: conn, owner: owner} do
      {:ok, show_live, _html} = live(conn, ~p"/owners/#{owner}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Owner"

      assert_patch(show_live, ~p"/owners/#{owner}/show/edit")

      assert show_live
             |> form("#owner-form", owner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#owner-form", owner: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/owners/#{owner}")

      html = render(show_live)
      assert html =~ "Owner updated successfully"
      assert html =~ "some updated name"
    end

    test "adds and removes pet and toy inputs", %{conn: conn, owner: owner} do
      %{id: pet2_id} =
        pet2 = Repo.insert!(%Pet{name: "Pam", owner_id: owner.id})

      %{id: toy2_id} = Repo.insert!(%Toy{name: "Plushy", pet_id: pet2.id})
      Repo.insert!(%Toy{name: "Stick", pet_id: pet2.id})
      {:ok, show_live, _html} = live(conn, ~p"/owners/#{owner}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Owner"

      assert_patch(show_live, ~p"/owners/#{owner}/show/edit")

      show_live
      |> element(
        ~s(a[phx-click="remove-toy"][phx-value-pet-index="1"][phx-value-toy-index="1"]),
        "remove"
      )
      |> render_click()

      refute show_live
             |> element("input#owner_pets_1_toys_1_name")
             |> has_element?()

      show_live
      |> element(
        ~s(a[phx-click="remove-pet"][phx-value-pet-index="0"]),
        "remove"
      )
      |> render_click()

      refute show_live
             |> element("input#owner_pets_0_name")
             |> has_element?()

      refute show_live
             |> element("input#owner_pets_0_toys_0_name")
             |> has_element?()

      assert show_live
             |> form("#owner-form")
             |> render_submit()

      assert_patch(show_live, ~p"/owners/#{owner}")

      assert [%Toy{id: ^toy2_id}] = Repo.all(Toy)
      assert [%Pet{id: ^pet2_id}] = Repo.all(Pet)
    end
  end
end
