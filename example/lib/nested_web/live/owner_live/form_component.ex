defmodule NestedWeb.OwnerLive.FormComponent do
  use NestedWeb, :live_component

  alias Nested.Members
  alias Phoenix.HTML.Form

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
      EctoNestedChangeset.append_at(socket.assigns.changeset, :pets, %{})

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add-toy", %{"pet-index" => index}, socket) do
    index = String.to_integer(index)

    changeset =
      EctoNestedChangeset.append_at(
        socket.assigns.changeset,
        [:pets, index, :toys],
        %{}
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

  defp deleted?(form) do
    input_value(form, :delete) in ["true", true]
  end

  @impl Phoenix.LiveComponent
  def handle_event("move-block-item-up", %{"index" => index}, socket) do
    changeset = socket.assigns.changeset

    index = String.to_integer(index)

    block_item = EctoNestedChangeset.get_at(changeset, [:pets, index])
    block_item_above = EctoNestedChangeset.get_at(changeset, [:pets, index - 1])

    changeset =
      changeset
      |> Ecto.Changeset.change()
      |> EctoNestedChangeset.update_at([:pets, index - 1, :name], fn _ ->
        get_name(block_item)
      end)
      |> EctoNestedChangeset.update_at([:pets, index, :name], fn _ ->
        get_name(block_item_above)
      end)
      |> IO.inspect(label: "moved up ")

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "move-block-item-down",
        %{"index" => index},
        socket
      ) do
    changeset = socket.assigns.changeset
    index = String.to_integer(index)
    IO.inspect(socket.assigns.changeset)

    IO.inspect(EctoNestedChangeset.get_at(changeset, [:pets, index]),
      label: "above"
    )

    IO.inspect(
      EctoNestedChangeset.get_at(changeset, [:pets, index + 1]),
      label: "below"
    )

    block_item = EctoNestedChangeset.get_at(changeset, [:pets, index])
    block_item_below = EctoNestedChangeset.get_at(changeset, [:pets, index + 1])

    changeset =
      changeset
      |> Ecto.Changeset.change()
      |> EctoNestedChangeset.update_at([:pets, index, :name], fn _ ->
        get_name(block_item_below)
      end)
      |> EctoNestedChangeset.update_at([:pets, index + 1, :name], fn _ ->
        get_name(block_item)
      end)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp get_name(%Ecto.Changeset{changes: %{}} = cs) do
    {_, name} = Ecto.Changeset.fetch_field(cs, :name)
    name
  end

  defp get_name(%Ecto.Changeset{changes: %{name: name}} = cs) do
    name
  end

  defp get_name(%Nested.Members.Pet{} = pet) do
    pet.name
  end

  defp has_more_than_one_block_item?(%Form{source: %{changes: %{pets: pets}}}) do
    length =
      pets
      |> Enum.reject(&(&1.changes == %{delete: true}))
      |> length()

    if length > 1, do: true, else: false
  end

  defp has_more_than_one_block_item?(%Phoenix.HTML.Form{data: %{pets: pets}}) do
    if length(pets) > 1, do: true, else: false
  end

  defp not_last_block_item?(%Form{source: %{changes: %{pets: pets}}}, index) do
    length =
      pets
      |> Enum.reject(&(&1.changes == %{delete: true}))
      |> length()

    if length - 1 == index, do: false, else: true
  end

  defp not_last_block_item?(%Phoenix.HTML.Form{data: %{pets: pets}}, index) do
    if length(pets) - 1 == index, do: false, else: true
  end
end
