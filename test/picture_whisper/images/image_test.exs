defmodule PictureWhisper.Images.ImageTest do
  use PictureWhisper.DataCase

  alias PictureWhisper.Images.Image

  describe "image" do
    @valid_attrs %{prompt: "some prompt", url: "some url", quality: "standard", size: "1024x1024", user_id: 1}
    @invalid_attrs %{prompt: nil, url: nil, quality: nil, size: nil, user_id: nil}

    test "changeset with valid attributes" do
      changeset = Image.changeset(%Image{}, @valid_attrs)
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
      attrs = Map.put(@valid_attrs, :user_api_key, "some_api_key")
      changeset = Image.changeset(%Image{}, attrs)
      assert changeset.valid?
    end

    test "changeset does not require user_api_key" do
      changeset = Image.changeset(%Image{}, @valid_attrs)
      assert changeset.valid?
      refute Keyword.has_key?(changeset.errors, :user_api_key)
    end
  end
end
