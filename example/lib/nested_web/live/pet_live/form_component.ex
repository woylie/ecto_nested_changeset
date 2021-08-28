defmodule NestedWeb.PetLive.FormComponent do
  use NestedWeb, :live_component

  alias Nested.Members

  @impl true
  def update(%{pet: pet} = assigns, socket) do
    changeset = Members.change_pet(pet)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"pet" => pet_params}, socket) do
    changeset =
      socket.assigns.pet
      |> Members.change_pet(pet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"pet" => pet_params}, socket) do
    save_pet(socket, socket.assigns.action, pet_params)
  end

  defp save_pet(socket, :edit, pet_params) do
    case Members.update_pet(socket.assigns.pet, pet_params) do
      {:ok, _pet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pet updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_pet(socket, :new, pet_params) do
    case Members.create_pet(pet_params) do
      {:ok, _pet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pet created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
