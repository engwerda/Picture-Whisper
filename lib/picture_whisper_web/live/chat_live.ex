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
    # TODO: Implement OpenAI API call
    # For now, we'll just create a dummy image
    case Images.create_image(%{
      prompt: prompt,
      url: "https://via.placeholder.com/300",
      user_id: socket.assigns.current_user.id
    }) do
      {:ok, image} ->
        {:noreply,
         socket
         |> update(:images, fn images -> [image | images] end)
         |> assign(prompt: "")
         |> put_flash(:info, "Image generated successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
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
