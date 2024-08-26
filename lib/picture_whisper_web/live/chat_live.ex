defmodule PictureWhisperWeb.ChatLive do
  use PictureWhisperWeb, :live_view

  alias PictureWhisper.Images
  alias PictureWhisperWeb.UserAuth

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        UserAuth.get_current_user(session)
      end)

    if connected?(socket) do
      images = Images.list_images(socket.assigns.current_user)
      {:ok, assign(socket, images: images, prompt: "")}
    else
      {:ok, assign(socket, images: [], prompt: "")}
    end
  end

  @impl true
  def handle_event("delete_image", %{"id" => id}, socket) do
    image = Images.get_image!(id)
    
    case Images.delete_image(image) do
      {:ok, _} ->
        {:noreply,
         socket
         |> update(:images, fn images -> Enum.reject(images, &(&1.id == image.id)) end)
         |> put_flash(:info, "Image deleted successfully!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete image. Please try again.")}
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
            {:noreply, put_flash(socket, :error, "Failed to save image: #{inspect(reason)}")}
        end

      {:error, :timeout} ->
        {:noreply, put_flash(socket, :error, "Image generation timed out. Please try again.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to generate image: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-4">Generate Images</h1>
      <form phx-submit="generate" class="mb-4">
        <div class="flex">
          <input
            type="text"
            name="prompt"
            value={@prompt}
            placeholder="Enter your prompt"
            class="flex-grow rounded-l-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
          />
          <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded-r-md">
            Generate
          </button>
        </div>
      </form>
      <div class="space-y-4">
        <%= for image <- @images do %>
          <div class="border rounded-md p-4">
            <p class="mb-2"><%= image.prompt %></p>
            <img src={image.url} alt={image.prompt} class="w-full h-auto" />
            <div class="flex justify-between items-center mt-2">
              <a href={image.url} target="_blank" rel="noopener noreferrer" class="text-blue-500 hover:underline">
                Open in new tab
              </a>
              <button phx-click="delete_image" phx-value-id={image.id} class="text-red-500 hover:text-red-700">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
