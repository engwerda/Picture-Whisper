defmodule PictureWhisperWeb.ImageLive.Index do
  use PictureWhisperWeb, :live_view

  alias PictureWhisper.Images

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, images: list_images(socket.assigns.current_user), generated_image_url: nil)}
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

  @impl true
  def handle_event("generate_image", %{"prompt" => prompt}, socket) do
    case Images.generate_image(prompt, socket.assigns.current_user) do
      {:ok, image_url} ->
        {:noreply, assign(socket, generated_image_url: image_url)}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to generate image: #{reason}")}
    end
  end
end
