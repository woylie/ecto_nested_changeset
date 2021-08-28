defmodule NestedWeb.ToyLiveTest do
  use NestedWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Nested.Members

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp fixture(:toy) do
    {:ok, toy} = Members.create_toy(@create_attrs)
    toy
  end

  defp create_toy(_) do
    toy = fixture(:toy)
    %{toy: toy}
  end

  describe "Index" do
    setup [:create_toy]

    test "lists all toys", %{conn: conn, toy: toy} do
      {:ok, _index_live, html} = live(conn, Routes.toy_index_path(conn, :index))

      assert html =~ "Listing Toys"
      assert html =~ toy.name
    end

    test "saves new toy", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.toy_index_path(conn, :index))

      assert index_live |> element("a", "New Toy") |> render_click() =~
               "New Toy"

      assert_patch(index_live, Routes.toy_index_path(conn, :new))

      assert index_live
             |> form("#toy-form", toy: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#toy-form", toy: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.toy_index_path(conn, :index))

      assert html =~ "Toy created successfully"
      assert html =~ "some name"
    end

    test "updates toy in listing", %{conn: conn, toy: toy} do
      {:ok, index_live, _html} = live(conn, Routes.toy_index_path(conn, :index))

      assert index_live |> element("#toy-#{toy.id} a", "Edit") |> render_click() =~
               "Edit Toy"

      assert_patch(index_live, Routes.toy_index_path(conn, :edit, toy))

      assert index_live
             |> form("#toy-form", toy: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#toy-form", toy: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.toy_index_path(conn, :index))

      assert html =~ "Toy updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes toy in listing", %{conn: conn, toy: toy} do
      {:ok, index_live, _html} = live(conn, Routes.toy_index_path(conn, :index))

      assert index_live |> element("#toy-#{toy.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#toy-#{toy.id}")
    end
  end

  describe "Show" do
    setup [:create_toy]

    test "displays toy", %{conn: conn, toy: toy} do
      {:ok, _show_live, html} = live(conn, Routes.toy_show_path(conn, :show, toy))

      assert html =~ "Show Toy"
      assert html =~ toy.name
    end

    test "updates toy within modal", %{conn: conn, toy: toy} do
      {:ok, show_live, _html} = live(conn, Routes.toy_show_path(conn, :show, toy))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Toy"

      assert_patch(show_live, Routes.toy_show_path(conn, :edit, toy))

      assert show_live
             |> form("#toy-form", toy: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#toy-form", toy: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.toy_show_path(conn, :show, toy))

      assert html =~ "Toy updated successfully"
      assert html =~ "some updated name"
    end
  end
end
