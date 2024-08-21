defmodule PictureWhisperWeb.ImageLive.Index do
  use PictureWhisperWeb, :live_view

  alias PictureWhisper.Images

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :images, list_images(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Images")
    |> assign(:image, nil)
  end

  defp list_images(user) do
    Images.list_images(user)
  end
end
