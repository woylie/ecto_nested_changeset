defmodule NestedWeb.OwnerLiveTest do
  use NestedWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Nested.Members

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp fixture(:owner) do
    {:ok, owner} = Members.create_owner(@create_attrs)
    owner
  end

  defp create_owner(_) do
    owner = fixture(:owner)
    %{owner: owner}
  end

  describe "Index" do
    setup [:create_owner]

    test "lists all owners", %{conn: conn, owner: owner} do
      {:ok, _index_live, html} =
        live(conn, Routes.owner_index_path(conn, :index))

      assert html =~ "Listing Owners"
      assert html =~ owner.name
    end

    test "saves new owner", %{conn: conn} do
      {:ok, index_live, _html} =
        live(conn, Routes.owner_index_path(conn, :index))

      assert index_live |> element("a", "New Owner") |> render_click() =~
               "New Owner"

      assert_patch(index_live, Routes.owner_index_path(conn, :new))

      assert index_live
             |> form("#owner-form", owner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#owner-form", owner: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.owner_index_path(conn, :index))

      assert html =~ "Owner created successfully"
      assert html =~ "some name"
    end

    test "updates owner in listing", %{conn: conn, owner: owner} do
      {:ok, index_live, _html} =
        live(conn, Routes.owner_index_path(conn, :index))

      assert index_live
             |> element("#owner-#{owner.id} a", "Edit")
             |> render_click() =~
               "Edit Owner"

      assert_patch(index_live, Routes.owner_index_path(conn, :edit, owner))

      assert index_live
             |> form("#owner-form", owner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#owner-form", owner: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.owner_index_path(conn, :index))

      assert html =~ "Owner updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes owner in listing", %{conn: conn, owner: owner} do
      {:ok, index_live, _html} =
        live(conn, Routes.owner_index_path(conn, :index))

      assert index_live
             |> element("#owner-#{owner.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#owner-#{owner.id}")
    end
  end

  describe "Show" do
    setup [:create_owner]

    test "displays owner", %{conn: conn, owner: owner} do
      {:ok, _show_live, html} =
        live(conn, Routes.owner_show_path(conn, :show, owner))

      assert html =~ "Show Owner"
      assert html =~ owner.name
    end

    test "updates owner within modal", %{conn: conn, owner: owner} do
      {:ok, show_live, _html} =
        live(conn, Routes.owner_show_path(conn, :show, owner))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Owner"

      assert_patch(show_live, Routes.owner_show_path(conn, :edit, owner))

      assert show_live
             |> form("#owner-form", owner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#owner-form", owner: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.owner_show_path(conn, :show, owner))

      assert html =~ "Owner updated successfully"
      assert html =~ "some updated name"
    end
  end
end
