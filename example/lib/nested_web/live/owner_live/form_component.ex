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
    owner_params = prepare_params(owner_params)

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
    index = String.to_integer(index)

    changeset =
      EctoNestedChangeset.append_at(
        socket.assigns.changeset,
        [:pets, index, :toys],
        %Toy{}
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("remove-pet", %{"pet-index" => index}, socket) do
    index = String.to_integer(index)

    changeset =
      EctoNestedChangeset.delete_at(
        socket.assigns.changeset,
        [:pets, index],
        mode: {:flag, :delete}
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "remove-toy",
        %{"pet-index" => pet_index, "toy-index" => toy_index},
        socket
      ) do
    pet_index = String.to_integer(pet_index)
    toy_index = String.to_integer(toy_index)

    changeset =
      EctoNestedChangeset.delete_at(
        socket.assigns.changeset,
        [:pets, pet_index, :toys, toy_index],
        mode: {:flag, :delete}
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

  # puts empty lists into association fields if no associations were added
  defp prepare_params(owner_params) do
    owner_params
    |> Map.put_new("pets", [])
    |> Map.update!(
      "pets",
      &Enum.into(&1, %{}, fn {key, pet} ->
        {key, Map.put_new(pet, "toys", [])}
      end)
    )
  end

  defp deleted?(form) do
    input_value(form, :delete) in ["true", true]
  end
end
