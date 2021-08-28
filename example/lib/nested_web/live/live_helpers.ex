defmodule NestedWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `NestedWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, NestedWeb.OwnerLive.FormComponent,
        id: @owner.id || :new,
        action: @live_action,
        owner: @owner,
        return_to: Routes.owner_index_path(@socket, :index) %>
  """
  def live_modal(_socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(NestedWeb.ModalComponent, modal_opts)
  end
end
