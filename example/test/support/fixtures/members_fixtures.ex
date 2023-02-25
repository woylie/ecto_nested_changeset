defmodule Nested.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Nested.Members` context.
  """

  @doc """
  Generate an owner.
  """
  def owner_fixture(attrs \\ %{}) do
    {:ok, owner} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Nested.Members.create_owner()

    owner
  end
end
