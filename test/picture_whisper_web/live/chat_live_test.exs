defmodule PictureWhisperWeb.ChatLiveTest do
  use PictureWhisperWeb.ConnCase

  import Phoenix.LiveViewTest
  import PictureWhisper.ImagesFixtures
  import PictureWhisper.AccountsFixtures

  alias PictureWhisper.Images

  @create_attrs %{prompt: "some prompt", size: "1024x1024", quality: "standard"}

  setup %{conn: conn} do
    user = user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  describe "Chat page" do
    test "displays generate images form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/chat")
      assert html =~ "Generate Images"
      assert has_element?(view, "form")
      assert has_element?(view, "input[name='prompt']")
      assert has_element?(view, "select[name='size']")
      assert has_element?(view, "select[name='quality']")
      assert has_element?(view, "button", "Generate")
    end

    test "generates an image", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      # Mock the image generation
      test_pid = self()
      Images.subscribe("user_images:#{user.id}")

      generation_id = "test_generation_id"
      url = "/uploads/test_image.png"

      send(view.pid, {:image_generated, generation_id, {:ok, %{url: url, prompt: @create_attrs.prompt}}})

      # Assert that the image is displayed
      assert_receive {:image_generated, ^generation_id, {:ok, _}}
      html = render(view)
      assert html =~ url
      assert html =~ @create_attrs.prompt
    end

    test "displays error toast on image generation failure", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/chat")

      generation_id = "test_generation_id"
      error_message = "Failed to generate image"

      send(view.pid, {:image_generated, generation_id, {:error, error_message}})

      # Assert that the error toast is displayed
      assert render(view) =~ error_message
    end

    test "deletes an image", %{conn: conn, user: user} do
      image = image_fixture(%{user_id: user.id})
      {:ok, view, _html} = live(conn, ~p"/chat")

      assert has_element?(view, "#image-#{image.id}")

      view
      |> element("#image-#{image.id} button", "Delete this image")
      |> render_click()

      # Assert that the image is no longer displayed
      refute has_element?(view, "#image-#{image.id}")
    end

    test "opens and closes image modal", %{conn: conn, user: user} do
      image = image_fixture(%{user_id: user.id})
      {:ok, view, _html} = live(conn, ~p"/chat")

      view
      |> element("#image-#{image.id} button", "View full screen")
      |> render_click()

      # Assert that the modal is displayed
      assert has_element?(view, "div[phx-click='close_modal']")

      view
      |> element("button", "Close")
      |> render_click()

      # Assert that the modal is closed
      refute has_element?(view, "div[phx-click='close_modal']")
    end

    test "loads more images", %{conn: conn, user: user} do
      # Create 15 images (more than the default per page)
      for _ <- 1..15 do
        image_fixture(%{user_id: user.id})
      end

      {:ok, view, html} = live(conn, ~p"/chat")

      # Assert that the initial page doesn't show all images
      assert html =~ "Load More"

      view
      |> element("button", "Load More")
      |> render_click()

      # Assert that more images are loaded
      updated_html = render(view)
      refute updated_html =~ "Load More"
    end
  end
end
