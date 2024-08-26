defmodule PictureWhisperWeb.HomeLive do
  use PictureWhisperWeb, :live_view

  def mount(_params, session, socket) do
    current_user = PictureWhisperWeb.UserAuth.get_current_user(session)
    {:ok, assign(socket, current_user: current_user)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @current_user do %>
        <div class="max-w-2xl mx-auto text-center">
          <h1 class="text-4xl font-bold mb-4">Welcome back to Picture Whisper</h1>
          <p class="text-xl mb-8">
            Ready to generate more amazing images?
          </p>
          <div>
            <.link
              navigate={~p"/chat"}
              class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
            >
              Image Generator
            </.link>
          </div>
        </div>
      <% else %>
        <div class="max-w-2xl mx-auto text-center">
          <h1 class="text-4xl font-bold mb-4">Welcome to Picture Whisper</h1>
          <p class="text-xl mb-8">
            Generate amazing images from text prompts using AI technology.
          </p>
          <div class="space-x-4">
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
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
