defmodule PictureWhisperWeb.RouterTest do
  use PictureWhisperWeb.ConnCase

  import PictureWhisper.AccountsFixtures

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome to Picture Whisper"
  end

  describe "authentication routes" do
    test "GET /users/register", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      assert html_response(conn, 200) =~ "Register"
    end

    test "GET /users/log_in", %{conn: conn} do
      conn = get(conn, ~p"/users/log_in")
      assert html_response(conn, 200) =~ "Log in"
    end

    test "GET /users/reset_password", %{conn: conn} do
      conn = get(conn, ~p"/users/reset_password")
      assert html_response(conn, 200) =~ "Forgot your password?"
    end
  end

  describe "authenticated routes" do
    setup [:register_and_log_in_user]

    test "GET /chat", %{conn: conn} do
      conn = get(conn, ~p"/chat")
      assert html_response(conn, 200) =~ "Generate Images"
    end

    test "GET /users/settings", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      assert html_response(conn, 200) =~ "Settings"
    end
  end

  describe "unauthenticated access" do
    test "GET /chat redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/chat")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "GET /users/settings redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end

  describe "logout" do
    test "DELETE /users/log_out logs out the user", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> delete(~p"/users/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
    end
  end
end
