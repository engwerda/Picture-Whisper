defmodule PictureWhisperWeb.HomeLiveTest do
  use PictureWhisperWeb.ConnCase

  import Phoenix.LiveViewTest
  import PictureWhisper.AccountsFixtures

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Welcome to Picture Whisper"
    assert render(page_live) =~ "Welcome to Picture Whisper"
  end

  test "displays sign up and log in links when not logged in", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/")
    assert render(page_live) =~ "Sign up"
    assert render(page_live) =~ "Log in"
  end

  test "displays welcome back message and image generator link when logged in", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    {:ok, page_live, _html} = live(conn, "/")
    assert render(page_live) =~ "Welcome back to Picture Whisper"
    assert render(page_live) =~ "Image Generator"
  end

  test "navigates to chat page when clicking image generator", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    {:ok, page_live, _html} = live(conn, "/")

    assert {:error, {:live_redirect, %{to: "/chat"}}} =
             page_live
             |> element("a", "Image Generator")
             |> render_click()
  end
end
