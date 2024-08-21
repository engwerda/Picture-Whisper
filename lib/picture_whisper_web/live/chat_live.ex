defmodule PictureWhisperWeb.ChatLive do
  use PictureWhisperWeb, :live_view

  alias PictureWhisper.Images
  alias PictureWhisper.Images.Image

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      images = Images.list_images(socket.assigns.current_user)
      {:ok, assign(socket, images: images, prompt: "")}
    else
      {:ok, assign(socket, images: [], prompt: "")}
    end
  end

  @impl true
  def handle_event("generate", %{"prompt" => prompt}, socket) do
    case Images.generate_image(prompt, socket.assigns.current_user) do
      {:ok, image_data} ->
        case Images.save_image(image_data, prompt, socket.assigns.current_user.id) do
          {:ok, image} ->
            {:noreply,
             socket
             |> update(:images, fn images -> [image | images] end)
             |> assign(prompt: "")
             |> put_flash(:info, "Image generated successfully!")}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Failed to save image: #{reason}")}
        end

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to generate image: #{reason}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-4">Chat</h1>
      <form phx-submit="generate" class="mb-4">
        <div class="flex">
          <input
            type="text"
            name="prompt"
            value={@prompt}
            placeholder="Enter your prompt"
            class="flex-grow rounded-l-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
          />
          <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded-r-md">Generate</button>
        </div>
      </form>
      <div class="space-y-4">
        <%= for image <- @images do %>
          <div class="border rounded-md p-4">
            <p class="mb-2"><%= image.prompt %></p>
            <img src={image.url} alt={image.prompt} class="w-full h-auto" />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
