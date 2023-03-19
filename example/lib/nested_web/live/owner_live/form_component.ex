defmodule NestedWeb.OwnerLive.FormComponent do
  use NestedWeb, :live_component

  alias Nested.Members
  alias Phoenix.HTML.Form

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          Use this form to manage owner records in your database.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="owner-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <fieldset>
          <legend>Pets</legend>

          <div class="clear-both">
            <.inputs_for :let={fp} field={@form[:pets]}>
              <.input field={fp[:delete]} type="hidden" />

              <div :if={!deleted?(fp)}>
                <.input field={fp[:name]} type="text" label="Name" />
                <.link
                  phx-click="remove-pet"
                  phx-value-pet-index={fp.index}
                  phx-target={@myself}
                  class="flex items-center"
                >
                  <Heroicons.x_mark mini class="h-4 w-4" /> remove
                </.link>
              </div>

              <fieldset>
                <legend>Toys</legend>
                <div class="clear-both">
                  <.inputs_for :let={ft} field={fp[:toys]}>
                    <.input field={ft[:delete]} type="hidden" />
                    <div :if={!deleted?(ft)} class="mt-4">
                      <.input field={ft[:name]} type="text" label="Name" />
                      <.link
                        phx-click="remove-toy"
                        phx-value-pet-index={fp.index}
                        phx-value-toy-index={ft.index}
                        phx-target={@myself}
                        class="flex items-center"
                      >
                        <Heroicons.x_mark mini class="h-4 w-4" /> remove
                      </.link>
                    </div>
                  </.inputs_for>

                  <div class="mt-4">
                    <.link
                      phx-click="add-toy"
                      phx-value-pet-index={fp.index}
                      phx-target={@myself}
                      class="flex items-center"
                    >
                      <Heroicons.plus mini class="h-4 w-4" /> add toy
                    </.link>
                  </div>
                </div>
              </fieldset>
            </.inputs_for>

            <div class="mt-4">
              <.link
                phx-click="add-pet"
                phx-target={@myself}
                class="flex items-center mt-4"
              >
                <Heroicons.plus mini class="h-4 w-4" /> add pet
              </.link>
            </div>
          </div>
        </fieldset>
        <:actions>
          <.button phx-disable-with="Saving...">Save Owner</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{owner: owner} = assigns, socket) do
    changeset = Members.change_owner(owner)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"owner" => owner_params}, socket) do
    changeset =
      socket.assigns.owner
      |> Members.change_owner(owner_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"owner" => owner_params}, socket) do
    save_owner(socket, socket.assigns.action, owner_params)
  end

  def handle_event("add-pet", _, socket) do
    changeset =
      EctoNestedChangeset.append_at(socket.assigns.form.source, :pets, %{})

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("add-toy", %{"pet-index" => index}, socket) do
    index = String.to_integer(index)

    changeset =
      EctoNestedChangeset.append_at(
        socket.assigns.form.source,
        [:pets, index, :toys],
        %{}
      )

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("remove-pet", %{"pet-index" => index}, socket) do
    index = String.to_integer(index)

    changeset =
      EctoNestedChangeset.delete_at(
        socket.assigns.form.source,
        [:pets, index],
        mode: {:flag, :delete}
      )

    {:noreply, assign_form(socket, changeset)}
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
        socket.assigns.form.source,
        [:pets, pet_index, :toys, toy_index],
        mode: {:flag, :delete}
      )

    {:noreply, assign_form(socket, changeset)}
  end

  defp save_owner(socket, :edit, owner_params) do
    case Members.update_owner(socket.assigns.owner, owner_params) do
      {:ok, owner} ->
        notify_parent({:saved, owner})

        {:noreply,
         socket
         |> put_flash(:info, "Owner updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_owner(socket, :new, owner_params) do
    case Members.create_owner(owner_params) do
      {:ok, owner} ->
        notify_parent({:saved, owner})

        {:noreply,
         socket
         |> put_flash(:info, "Owner created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp deleted?(form) do
    Form.normalize_value("checkbox", form[:delete].value)
  end
end
