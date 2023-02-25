defmodule NestedWeb.Router do
  use NestedWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NestedWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", NestedWeb do
    pipe_through :browser

    live "/", OwnerLive.Index, :index

    live "/owners", OwnerLive.Index, :index
    live "/owners/new", OwnerLive.Index, :new
    live "/owners/:id/edit", OwnerLive.Index, :edit

    live "/owners/:id", OwnerLive.Show, :show
    live "/owners/:id/show/edit", OwnerLive.Show, :edit
  end
end
