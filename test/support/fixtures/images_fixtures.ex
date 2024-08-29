defmodule PictureWhisper.ImagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PictureWhisper.Images` context.
  """

  alias PictureWhisper.Images
  alias PictureWhisper.Accounts

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        name: "Test User",
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Accounts.register_user()

    user
  end

  def image_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()

    {:ok, image} =
      attrs
      |> Enum.into(%{
        prompt: "some prompt",
        url: "/uploads/some_image.png",
        quality: "standard",
        size: "1024x1024",
        user_id: user.id
      })
      |> Images.create_image()

    image
  end
end
