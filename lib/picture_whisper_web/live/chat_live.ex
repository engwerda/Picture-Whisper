defmodule PictureWhisperWeb.ChatLive do
  use PictureWhisperWeb, :live_view

  alias PictureWhisper.Images
  alias PictureWhisperWeb.UserAuth

  @images_per_page 10
  @size_options [
    {"Square", "1024x1024"},
    {"Portrait", "1024x1792"},
    {"Landscape", "1792x1024"}
  ]
  @quality_options ["standard", "hd"]

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        UserAuth.get_current_user(session)
      end)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        PictureWhisper.PubSub,
        "user_images:#{socket.assigns.current_user.id}"
      )

      images = Images.list_images(socket.assigns.current_user, 1, @images_per_page)
      total_images = Images.count_images(socket.assigns.current_user)
      total_pages = ceil(total_images / @images_per_page)

      {:ok,
       assign(socket,
         images: images,
         prompt: "",
         size: List.first(@size_options),
         quality: List.first(@quality_options),
         size_options: @size_options,
         quality_options: @quality_options,
         page: 1,
         total_pages: total_pages,
         pending_generations: %{}
       )}
    else
      {:ok,
       assign(socket,
         images: [],
         prompt: "",
         size: List.first(@size_options),
         quality: List.first(@quality_options),
         size_options: @size_options,
         quality_options: @quality_options,
         page: 1,
         total_pages: 1,
         pending_generations: %{}
       )}
    end
  end

  @impl true
  def handle_event("load_more", _, socket) do
    %{page: page, current_user: current_user} = socket.assigns
    next_page = page + 1
    images = Images.list_images(current_user, next_page, @images_per_page)

    {:noreply,
     socket
     |> update(:images, &(&1 ++ images))
     |> assign(page: next_page)}
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
  def handle_event(
        "generate",
        %{"prompt" => prompt, "size" => size, "quality" => quality},
        socket
      ) do
    generation_id = UUID.uuid4()

    socket =
      socket
      |> update(:pending_generations, &Map.put(&1, generation_id, prompt))
      |> assign(prompt: "", size: size, quality: quality)

    # Start the generation process asynchronously
    Images.generate_image_async(prompt, size, quality, socket.assigns.current_user, generation_id)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:image_generated, generation_id, result}, socket) do
    socket =
      case result do
        {:ok, image} ->
          socket
          |> update(:images, fn images -> [image | images] end)
          |> put_flash(:info, "Image generated successfully!")

        {:error, reason} ->
          put_flash(socket, :error, "Failed to generate image: #{inspect(reason)}")
      end

    socket = update(socket, :pending_generations, &Map.delete(&1, generation_id))
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "generate",
        %{"prompt" => prompt, "size" => size, "quality" => quality},
        socket
      ) do
    generation_id = UUID.uuid4()

    socket =
      socket
      |> update(:pending_generations, &Map.put(&1, generation_id, prompt))
      |> assign(prompt: "")

    # Start the generation process asynchronously
    Images.generate_image_async(prompt, size, quality, socket.assigns.current_user, generation_id)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-4">Generate Images</h1>
      <form phx-submit="generate" class="mb-4">
        <div class="space-y-4">
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
          <div class="flex space-x-4">
            <div class="flex-1">
              <label for="size" class="block text-sm font-medium text-gray-700">Size</label>
              <select
                id="size"
                name="size"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <%= for {name, value} <- @size_options do %>
                  <option value={value} selected={@size == value}><%= name %></option>
                <% end %>
              </select>
            </div>
            <div class="flex-1">
              <label for="quality" class="block text-sm font-medium text-gray-700">Quality</label>
              <select
                id="quality"
                name="quality"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <%= for quality <- @quality_options do %>
                  <option value={quality} selected={@quality == quality}><%= quality %></option>
                <% end %>
              </select>
            </div>
          </div>
        </div>
      </form>

      <%= if map_size(@pending_generations) > 0 do %>
        <div class="mb-4">
          <h2 class="text-lg font-semibold mb-2">Pending Generations</h2>
          <%= for {id, prompt} <- @pending_generations do %>
            <div class="flex items-center space-x-2 mb-2">
              <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-900"></div>
              <span class="text-sm text-gray-600"><%= prompt %></span>
            </div>
          <% end %>
        </div>
      <% end %>

      <div class="space-y-4" id="images-container">
        <%= for image <- @images do %>
          <div class="border rounded-md p-4" id={"image-#{image.id}"} phx-hook="ImageLoaded">
            <p class="mb-2"><%= image.prompt %></p>
            <img src={image.url} alt={image.prompt} class="w-full h-auto" />
            <div class="flex justify-between items-center mt-2">
              <a
                href={image.url}
                target="_blank"
                rel="noopener noreferrer"
                class="text-blue-500 hover:underline"
              >
                Open in new tab
              </a>
              <div class="relative group">
                <button
                  phx-click="delete_image"
                  phx-value-id={image.id}
                  class="text-red-500 hover:text-red-700"
                  title="Delete this image"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </button>
                <div class="absolute bottom-full right-0 mb-2 w-48 p-2 text-sm bg-white rounded-md shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 ease-in-out">
                  <div class="relative">
                    <p class="text-gray-700">
                      Click to delete this image permanently. This action cannot be undone.
                    </p>
                    <div class="absolute w-3 h-3 bg-white transform rotate-45 -bottom-1.5 right-2">
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @page < @total_pages do %>
        <div class="mt-4 text-center">
          <button phx-click="load_more" class="bg-blue-500 text-white px-4 py-2 rounded-md">
            Load More
          </button>
        </div>
      <% end %>
    </div>
    """
  end
end
