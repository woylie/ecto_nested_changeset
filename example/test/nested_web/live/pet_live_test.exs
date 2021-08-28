defmodule NestedWeb.PetLiveTest do
  use NestedWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Nested.Members

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp fixture(:pet) do
    {:ok, pet} = Members.create_pet(@create_attrs)
    pet
  end

  defp create_pet(_) do
    pet = fixture(:pet)
    %{pet: pet}
  end

  describe "Index" do
    setup [:create_pet]

    test "lists all pets", %{conn: conn, pet: pet} do
      {:ok, _index_live, html} = live(conn, Routes.pet_index_path(conn, :index))

      assert html =~ "Listing Pets"
      assert html =~ pet.name
    end

    test "saves new pet", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.pet_index_path(conn, :index))

      assert index_live |> element("a", "New Pet") |> render_click() =~
               "New Pet"

      assert_patch(index_live, Routes.pet_index_path(conn, :new))

      assert index_live
             |> form("#pet-form", pet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pet-form", pet: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pet_index_path(conn, :index))

      assert html =~ "Pet created successfully"
      assert html =~ "some name"
    end

    test "updates pet in listing", %{conn: conn, pet: pet} do
      {:ok, index_live, _html} = live(conn, Routes.pet_index_path(conn, :index))

      assert index_live |> element("#pet-#{pet.id} a", "Edit") |> render_click() =~
               "Edit Pet"

      assert_patch(index_live, Routes.pet_index_path(conn, :edit, pet))

      assert index_live
             |> form("#pet-form", pet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pet-form", pet: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pet_index_path(conn, :index))

      assert html =~ "Pet updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes pet in listing", %{conn: conn, pet: pet} do
      {:ok, index_live, _html} = live(conn, Routes.pet_index_path(conn, :index))

      assert index_live |> element("#pet-#{pet.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#pet-#{pet.id}")
    end
  end

  describe "Show" do
    setup [:create_pet]

    test "displays pet", %{conn: conn, pet: pet} do
      {:ok, _show_live, html} = live(conn, Routes.pet_show_path(conn, :show, pet))

      assert html =~ "Show Pet"
      assert html =~ pet.name
    end

    test "updates pet within modal", %{conn: conn, pet: pet} do
      {:ok, show_live, _html} = live(conn, Routes.pet_show_path(conn, :show, pet))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Pet"

      assert_patch(show_live, Routes.pet_show_path(conn, :edit, pet))

      assert show_live
             |> form("#pet-form", pet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#pet-form", pet: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pet_show_path(conn, :show, pet))

      assert html =~ "Pet updated successfully"
      assert html =~ "some updated name"
    end
  end
end
