defmodule NestedWeb.ToyLive.FormComponent do
  use NestedWeb, :live_component

  alias Nested.Members

  @impl true
  def update(%{toy: toy} = assigns, socket) do
    changeset = Members.change_toy(toy)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"toy" => toy_params}, socket) do
    changeset =
      socket.assigns.toy
      |> Members.change_toy(toy_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"toy" => toy_params}, socket) do
    save_toy(socket, socket.assigns.action, toy_params)
  end

  defp save_toy(socket, :edit, toy_params) do
    case Members.update_toy(socket.assigns.toy, toy_params) do
      {:ok, _toy} ->
        {:noreply,
         socket
         |> put_flash(:info, "Toy updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_toy(socket, :new, toy_params) do
    case Members.create_toy(toy_params) do
      {:ok, _toy} ->
        {:noreply,
         socket
         |> put_flash(:info, "Toy created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
