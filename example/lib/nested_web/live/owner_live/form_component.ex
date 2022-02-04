defmodule NestedWeb.OwnerLive.FormComponent do
  use NestedWeb, :live_component

  alias Ecto.Changeset
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

      {:error, %Changeset{} = changeset} ->
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

      {:error, %Changeset{} = changeset} ->
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
    block_item = get_item_changeset(changeset, index)

    {previous_item_index, block_item_above} =
      find_previous_item(changeset, index - 1)

    changeset =
      changeset
      |> Changeset.change()
      |> EctoNestedChangeset.update_at(
        [:pets, previous_item_index, :name],
        fn _ -> get_name(block_item) end
      )
      |> EctoNestedChangeset.update_at(
        [:pets, index, :name],
        fn _ -> get_name(block_item_above) end
      )

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
    block_item = get_item_changeset(changeset, index)

    {next_item_index, block_item_below} = find_next_item(changeset, index + 1)

    changeset =
      changeset
      |> Changeset.change()
      |> EctoNestedChangeset.update_at([:pets, index, :name], fn _ ->
        get_name(block_item_below)
      end)
      |> EctoNestedChangeset.update_at([:pets, next_item_index, :name], fn _ ->
        get_name(block_item)
      end)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp find_next_item(%Changeset{} = changeset, index) do
    pet_cs = get_item_changeset(changeset, index)

    if Changeset.get_change(pet_cs, :delete) do
      find_next_item(changeset, index + 1)
    else
      {index, pet_cs}
    end
  end

  defp find_previous_item(changeset, index) do
    pet_cs = get_item_changeset(changeset, index)

    if Changeset.get_change(pet_cs, :delete) do
      find_next_item(changeset, index - 1)
    else
      {index, pet_cs}
    end
  end

  defp get_name(%Changeset{} = cs) do
    {_, name} = Changeset.fetch_field(cs, :name)
    name
  end

  defp get_item_changeset(changeset, index) do
    changeset
    |> EctoNestedChangeset.get_at([:pets, index])
    |> Changeset.change()
  end

  defp has_more_than_one_block_item?(%Form{source: %{changes: %{pets: pets}}}) do
    length =
      pets
      |> Enum.reject(&(&1.changes == %{delete: true}))
      |> length()

    if length > 0, do: true, else: false
  end

  defp has_more_than_one_block_item?(%Phoenix.HTML.Form{data: %{pets: pets}}) do
    if length(pets) > 1, do: true, else: false
  end

  defp not_first_block_item?(_, 0), do: false

  defp not_first_block_item?(%Form{source: %{changes: %{pets: pets}}}, index) do
    first_non_deleted_index =
      Enum.find_index(pets, fn pet -> is_not_deleted_item?(pet.changes) end)

    !(index == first_non_deleted_index)
  end

  defp not_first_block_item?(_, index) do
    if index != 0, do: true, else: false
  end

  defp is_not_deleted_item?(%{delete: true}), do: false
  defp is_not_deleted_item?(%{}), do: true

  defp not_last_block_item?(%Form{source: %{changes: %{pets: pets}}}, index) do
    length =
      pets
      |> Enum.reject(&(&1.changes == %{delete: true}))
      |> length()

    deleted_item_length = length(pets) - length

    if length - 1 == index - deleted_item_length, do: false, else: true
  end

  defp not_last_block_item?(%Phoenix.HTML.Form{data: %{pets: pets}}, index) do
    if length(pets) - 1 == index, do: false, else: true
  end
end
