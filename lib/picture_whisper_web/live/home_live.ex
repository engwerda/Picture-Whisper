defmodule PictureWhisperWeb.HomeLive do
  use PictureWhisperWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto text-center">
      <h1 class="text-4xl font-bold mb-4">Welcome to Picture Whisper</h1>
      <p class="text-xl mb-8">
        Generate amazing images from text prompts using AI technology.
      </p>
      <div class="space-x-4">
        <%= if @current_user do %>
          <.link
            navigate={~p"/images"}
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Generate Images
          </.link>
        <% else %>
          <.link
            navigate={~p"/users/register"}
            class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
          >
            Sign up
          </.link>
          <.link
            navigate={~p"/users/log_in"}
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Log in
          </.link>
        <% end %>
      </div>
    </div>
    """
  end
end
