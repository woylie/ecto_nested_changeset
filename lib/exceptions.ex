defmodule EctoNestedChangeset.NotLoadedError do
  @moduledoc """
  Raised when a relation field that is updated is not preloaded.
  """
  defexception [:field, :message]

  def exception(opts) do
    field = Keyword.fetch!(opts, :field)
    message = "field `#{inspect(field)}` is not loaded"
    %__MODULE__{field: field, message: message}
  end
end
