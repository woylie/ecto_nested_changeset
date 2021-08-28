defmodule NestedWeb.Router do
  use NestedWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NestedWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NestedWeb do
    pipe_through :browser

    live "/", PageLive, :index

    live "/owners", OwnerLive.Index, :index
    live "/owners/new", OwnerLive.Index, :new
    live "/owners/:id/edit", OwnerLive.Index, :edit

    live "/owners/:id", OwnerLive.Show, :show
    live "/owners/:id/show/edit", OwnerLive.Show, :edit

    live "/pets", PetLive.Index, :index
    live "/pets/new", PetLive.Index, :new
    live "/pets/:id/edit", PetLive.Index, :edit

    live "/pets/:id", PetLive.Show, :show
    live "/pets/:id/show/edit", PetLive.Show, :edit

    live "/toys", ToyLive.Index, :index
    live "/toys/new", ToyLive.Index, :new
    live "/toys/:id/edit", ToyLive.Index, :edit

    live "/toys/:id", ToyLive.Show, :show
    live "/toys/:id/show/edit", ToyLive.Show, :edit
  end
end
