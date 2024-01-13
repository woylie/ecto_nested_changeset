defmodule Nested.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Nested.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Nested.PubSub},
      # Start the Endpoint (http/https)
      NestedWeb.Endpoint
      # Start a worker by calling: Nested.Worker.start_link(arg)
      # {Nested.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nested.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NestedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
