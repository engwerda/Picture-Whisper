defmodule PictureWhisper.Images.ImageTest do
  use PictureWhisper.DataCase

  alias PictureWhisper.Images
  alias PictureWhisper.Images.Image
  import PictureWhisper.ImagesFixtures

  describe "image" do
    @invalid_attrs %{prompt: nil, url: nil, quality: nil, size: nil, user_id: nil}

    test "changeset with valid attributes" do
      user = user_fixture()
      valid_attrs = %{prompt: "some prompt", url: "some url", quality: "standard", size: "1024x1024", user_id: user.id}
      changeset = Image.changeset(%Image{}, valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Image.changeset(%Image{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset enforces required fields" do
      changeset = Image.changeset(%Image{}, %{})
      assert "can't be blank" in errors_on(changeset).prompt
      assert "can't be blank" in errors_on(changeset).url
      assert "can't be blank" in errors_on(changeset).quality
      assert "can't be blank" in errors_on(changeset).size
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "changeset allows optional user_api_key" do
      image = image_fixture()
      attrs = %{user_api_key: "some_api_key"}
      changeset = Image.changeset(image, attrs)
      assert changeset.valid?
    end

    test "changeset does not require user_api_key" do
      image = image_fixture()
      changeset = Image.changeset(image, %{})
      assert changeset.valid?
      refute Keyword.has_key?(changeset.errors, :user_api_key)
    end

    test "list_images returns all images for a user" do
      user = user_fixture()
      image = image_fixture(%{user: user})
      assert Images.list_images(user, 1, 10).entries == [image]
    end

    test "get_image! returns the image with given id" do
      image = image_fixture()
      assert Images.get_image!(image.id) == image
    end

    test "create_image/1 with valid data creates an image" do
      user = user_fixture()
      valid_attrs = %{prompt: "some prompt", url: "some url", quality: "standard", size: "1024x1024", user_id: user.id}

      assert {:ok, %Image{} = image} = Images.create_image(valid_attrs)
      assert image.prompt == "some prompt"
      assert image.url == "some url"
      assert image.quality == "standard"
      assert image.size == "1024x1024"
      assert image.user_id == user.id
    end

    test "create_image/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Images.create_image(@invalid_attrs)
    end

    test "delete_image_and_broadcast/1 deletes the image" do
      image = image_fixture()
      assert {:ok, %Image{}} = Images.delete_image_and_broadcast(image)
      assert_raise Ecto.NoResultsError, fn -> Images.get_image!(image.id) end
    end
  end
end
