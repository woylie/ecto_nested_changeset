defmodule NestedWeb.OwnerLive.FormComponent do
  use NestedWeb, :live_component

  alias Nested.Members
  alias Nested.Members.Pet
  alias Nested.Members.Toy

  @impl true
  def update(%{owner: owner} = assigns, socket) do
    changeset = Members.change_owner(owner)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"owner" => owner_params}, socket) do
    changeset =
      socket.assigns.owner
      |> Members.change_owner(owner_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"owner" => owner_params}, socket) do
    save_owner(socket, socket.assigns.action, owner_params)
  end

  def handle_event("add-pet", _, socket) do
    changeset =
      EctoNestedChangeset.append_at(socket.assigns.changeset, :pets, %Pet{
        toys: []
      })

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add-toy", %{"pet-index" => index}, socket) do
    index = String.to_integer(index) |> IO.inspect()

    changeset =
      EctoNestedChangeset.append_at(
        socket.assigns.changeset,
        [:pets, index, :toys],
        %Toy{}
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp save_owner(socket, :edit, owner_params) do
    case Members.update_owner(socket.assigns.owner, owner_params) do
      {:ok, _owner} ->
        {:noreply,
         socket
         |> put_flash(:info, "Owner updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_owner(socket, :new, owner_params) do
    case Members.create_owner(owner_params) do
      {:ok, _owner} ->
        {:noreply,
         socket
         |> put_flash(:info, "Owner created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
