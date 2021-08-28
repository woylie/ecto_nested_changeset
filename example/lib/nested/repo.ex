defmodule Nested.Repo do
  use Ecto.Repo,
    otp_app: :nested,
    adapter: Ecto.Adapters.Postgres
end
