defmodule PictureWhisperWeb.PageController do
  use PictureWhisperWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def redirect_to_chat(conn, _params) do
    redirect(conn, to: "/chat")
  end
end
