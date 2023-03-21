defmodule NestedWeb.Layouts do
  @moduledoc """
  Defines the layouts for live views.
  """
  use NestedWeb, :html

  embed_templates("layouts/*")
end
