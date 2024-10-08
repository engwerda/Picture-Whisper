defmodule PictureWhisperWeb.ChatLive do
  use PictureWhisperWeb, :live_view
  import LiveToast

  alias PictureWhisper.Images
  alias PictureWhisperWeb.UserAuth
  alias Timex

  @images_per_page 10
  @size_options [
    {"Square", "1024x1024"},
    {"Portrait", "1024x1792"},
    {"Landscape", "1792x1024"}
  ]
  @quality_options ["standard", "hd"]
  @max_global_key_images Application.compile_env(:picture_whisper, :max_global_key_images)

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

      images_page = Images.list_images(socket.assigns.current_user, 1, @images_per_page)
      total_images = Images.count_images(socket.assigns.current_user)
      total_pages = ceil(total_images / @images_per_page)

      {free_images_used, free_images_left} =
        Images.get_free_image_stats(socket.assigns.current_user)

      {:ok,
       assign(socket,
         images: images_page.entries,
         prompt: "",
         size: List.first(@size_options),
         quality: List.first(@quality_options),
         size_options: @size_options,
         quality_options: @quality_options,
         page: 1,
         total_pages: total_pages,
         pending_generations: %{},
         selected_image: nil,
         free_images_used: free_images_used,
         free_images_left: free_images_left,
         using_global_key: is_nil(socket.assigns.current_user.openai_api_key),
         max_global_key_images: @max_global_key_images
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
         pending_generations: %{},
         selected_image: nil,
         free_images_used: 0,
         free_images_left: @max_global_key_images,
         using_global_key: true,
         max_global_key_images: @max_global_key_images
       )}
    end
  end

  @impl true
  def handle_event("load_more", _, socket) do
    %{page: page, current_user: current_user, images: current_images} = socket.assigns
    next_page = page + 1
    new_images = Images.list_images(current_user, next_page, @images_per_page)

    {:noreply,
     socket
     |> assign(:images, current_images ++ new_images.entries)
     |> assign(:page, next_page)}
  end

  @impl true
  def handle_event("delete_image", %{"id" => id}, socket) do
    image = Images.get_image!(id)

    case Images.delete_image_and_broadcast(image) do
      {:ok, _} ->
        updated_images = Enum.reject(socket.assigns.images, &(&1.id == image.id))

        {:noreply,
         socket
         |> assign(:images, updated_images)
         |> put_toast(:warn, "Image deleted successfully!")}

      {:error, _} ->
        {:noreply, put_toast(socket, :error, "Failed to delete image. Please try again.")}
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
  def handle_event("open_modal", %{"id" => id}, socket) do
    image = Enum.find(socket.assigns.images, &(&1.id == String.to_integer(id)))
    {:noreply, assign(socket, selected_image: image)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, selected_image: nil)}
  end

  @impl true
  def handle_info({:image_deleted, deleted_image_id}, socket) do
    updated_images = Enum.reject(socket.assigns.images, &(&1.id == deleted_image_id))
    total_images = Images.count_images(socket.assigns.current_user)
    total_pages = ceil(total_images / @images_per_page)

    {:noreply,
     socket
     |> assign(:images, updated_images)
     |> assign(:total_images, total_images)
     |> assign(:total_pages, total_pages)
     |> put_toast(:warn, "An image has been deleted.")}
  end

  @impl true
  def handle_info({:image_generated, generation_id, result}, socket) do
    socket =
      case result do
        {:ok, _new_image} ->
          # Fetch the latest images
          total_images = Images.count_images(socket.assigns.current_user)
          total_pages = ceil(total_images / @images_per_page)

          {free_images_used, free_images_left} =
            Images.get_free_image_stats(socket.assigns.current_user)

          socket
          |> assign(
            :images,
            Images.list_images(socket.assigns.current_user, 1, @images_per_page).entries
          )
          |> assign(:page, 1)
          |> assign(:total_images, total_images)
          |> assign(:total_pages, total_pages)
          |> assign(:free_images_used, free_images_used)
          |> assign(:free_images_left, free_images_left)
          |> put_toast(:success, "Image generated successfully!")

        {:error, "Standard quality only allowed with global API key"} ->
          put_toast(
            socket,
            :error,
            "Only standard quality is allowed with the global API key. Please use your own API key for higher quality."
          )

        {:error, "Maximum number of images with global API key reached"} ->
          put_toast(
            socket,
            :error,
            "You've reached the maximum number of images with the global API key. Please use your own API key to generate more images."
          )

        {:error, reason} ->
          put_toast(socket, :error, "Failed to generate image: #{reason}")
      end

    socket = update(socket, :pending_generations, &Map.delete(&1, generation_id))
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-4">Generate Images</h1>
      <%= if @using_global_key do %>
        <div class="bg-blue-100 border-l-4 border-blue-500 text-blue-700 p-4 mb-4" role="alert">
          <p class="font-bold">Using free API key</p>
          <p>
            You have used <%= @free_images_used %> out of <%= @max_global_key_images %> free images. <%= @max_global_key_images -
              @free_images_used %> free images left.
          </p>
          <p class="mt-2">Add your own API key in the settings to remove this limit.</p>
        </div>
      <% end %>
      <%= if @selected_image do %>
        <div
          class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
          phx-click="close_modal"
        >
          <div
            class="bg-white p-4 rounded-lg w-full max-w-4xl max-h-[90vh] flex flex-col"
            phx-click-away="close_modal"
          >
            <div class="flex-grow overflow-auto">
              <img
                src={@selected_image.url}
                alt={@selected_image.prompt}
                class="w-full h-auto object-contain"
              />
            </div>
            <div class="mt-4 px-4 py-2 bg-white">
              <h3 class="text-lg font-semibold text-gray-800"><%= @selected_image.prompt %></h3>
              <div class="flex justify-between items-center text-sm text-gray-600 mt-2">
                <span>
                  <%= Timex.format!(
                    @selected_image.inserted_at,
                    "{Mfull} {D}, {YYYY} at {h12}:{m} {am}"
                  ) %>
                </span>
                <span><%= @selected_image.quality %> | <%= @selected_image.size %></span>
              </div>
            </div>
            <button
              phx-click="close_modal"
              class="mt-4 bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
            >
              Close
            </button>
          </div>
        </div>
      <% end %>
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
        <div class="mb-6">
          <h2 class="text-xl font-semibold mb-3">Pending Images</h2>
          <%= for {_id, prompt} <- @pending_generations do %>
            <div class="flex items-center space-x-3 mb-3 bg-blue-50 p-3 rounded-lg">
              <div class="animate-spin rounded-full h-8 w-8 border-4 border-blue-600 border-t-transparent">
              </div>
              <span class="text-base font-semibold text-gray"><%= prompt %></span>
            </div>
          <% end %>
        </div>
      <% end %>

      <div class="space-y-6" id="images-container">
        <%= for image <- @images do %>
          <div class="border rounded-md overflow-hidden shadow-md" id={"image-#{image.id}"}>
            <div class="bg-gray-100 px-4 py-2 border-b">
              <h3 class="text-lg font-semibold text-gray-800 truncate" title={image.prompt}>
                <%= image.prompt %>
              </h3>
            </div>
            <div class="cursor-pointer" phx-click="open_modal" phx-value-id={image.id}>
              <img src={image.url} alt={image.prompt} class="w-full h-auto" />
            </div>
            <div class="px-4 py-2 bg-white">
              <div class="flex justify-between items-center text-xs text-gray-500">
                <span title={Timex.format!(image.inserted_at, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}")}>
                  <%= Timex.format!(image.inserted_at, "{relative}", :relative) %>
                </span>
                <span><%= image.quality %> | <%= image.size %></span>
              </div>
              <div class="flex justify-between items-center mt-2">
                <button
                  phx-click="open_modal"
                  phx-value-id={image.id}
                  class="text-blue-500 hover:underline text-sm"
                >
                  View full screen
                </button>
                <div class="flex items-center space-x-2">
                  <a
                    href={image.url}
                    download
                    class="text-green-500 hover:text-green-700"
                    title="Download this image"
                    target="_blank"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                        clip-rule="evenodd"
                      />
                    </svg>
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
