defmodule NestedWeb.PetLive.Index do
  use NestedWeb, :live_view

  alias Nested.Members
  alias Nested.Members.Pet

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :pets, list_pets())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Pet")
    |> assign(:pet, Members.get_pet!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Pet")
    |> assign(:pet, %Pet{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Pets")
    |> assign(:pet, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pet = Members.get_pet!(id)
    {:ok, _} = Members.delete_pet(pet)

    {:noreply, assign(socket, :pets, list_pets())}
  end

  defp list_pets do
    Members.list_pets()
  end
end
