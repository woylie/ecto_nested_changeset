defmodule NestedWeb.ToyLive.Index do
  use NestedWeb, :live_view

  alias Nested.Members
  alias Nested.Members.Toy

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :toys, list_toys())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Toy")
    |> assign(:toy, Members.get_toy!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Toy")
    |> assign(:toy, %Toy{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Toys")
    |> assign(:toy, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    toy = Members.get_toy!(id)
    {:ok, _} = Members.delete_toy(toy)

    {:noreply, assign(socket, :toys, list_toys())}
  end

  defp list_toys do
    Members.list_toys()
  end
end
