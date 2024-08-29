defmodule PictureWhisper.Images.ImageTest do
  use PictureWhisper.DataCase

  alias PictureWhisper.Images
  alias PictureWhisper.Images.Image
  import PictureWhisper.ImagesFixtures
  import PictureWhisper.AccountsFixtures

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
defmodule PictureWhisper.ImagesTest do
  use PictureWhisper.DataCase

  alias PictureWhisper.Images
  alias PictureWhisper.Images.Image
  import PictureWhisper.ImagesFixtures
  import PictureWhisper.AccountsFixtures

  describe "images" do
    test "list_images/3 returns paginated list of images for a user" do
      user = user_fixture()
      image1 = image_fixture(%{user: user})
      image2 = image_fixture(%{user: user})
      _other_user_image = image_fixture()  # This should not be returned

      result = Images.list_images(user, 1, 10)
      assert length(result.entries) == 2
      assert MapSet.new(Enum.map(result.entries, & &1.id)) == MapSet.new([image2.id, image1.id])
    end

    test "count_images/1 returns the correct count of images for a user" do
      user = user_fixture()
      _image1 = image_fixture(%{user: user})
      _image2 = image_fixture(%{user: user})
      _other_user_image = image_fixture()  # This should not be counted

      assert Images.count_images(user) == 2
    end

    test "create_image/1 with valid data creates an image" do
      user = user_fixture()
      valid_attrs = %{prompt: "test prompt", url: "/uploads/test.png", quality: "standard", size: "1024x1024", user_id: user.id}

      assert {:ok, %Image{} = image} = Images.create_image(valid_attrs)
      assert image.prompt == "test prompt"
      assert image.url == "/uploads/test.png"
      assert image.quality == "standard"
      assert image.size == "1024x1024"
      assert image.user_id == user.id
    end

    test "generate_file_name/1 generates a unique file name with the given extension" do
      file_name = Images.generate_file_name("png")
      assert String.ends_with?(file_name, ".png")
      assert String.length(file_name) == 40  # 36 characters for UUID + 1 for dot + 3 for extension
    end

    test "get_file_extension/1 returns the correct file extension" do
      assert Images.get_file_extension("image/png") == "png"
      assert Images.get_file_extension("image/jpeg") == "jpg"
      assert Images.get_file_extension("unknown/type") == "png"
    end

    test "get_content_type/1 extracts the content type from headers" do
      headers = [{"Content-Type", "image/png"}]
      assert Images.get_content_type(headers) == "image/png"
    end

    test "get_free_image_stats/1 returns correct stats" do
      user = user_fixture()
      _image1 = image_fixture(%{user: user, user_api_key: nil})
      _image2 = image_fixture(%{user: user, user_api_key: nil})
      _image3 = image_fixture(%{user: user, user_api_key: "used"})

      assert Images.get_free_image_stats(user) == {2, 8}
    end
  end
end
