defmodule PictureWhisper.ImagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PictureWhisper.Images` context.
  """

  alias PictureWhisper.Images
  alias PictureWhisper.AccountsFixtures

  def image_fixture(attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()

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
