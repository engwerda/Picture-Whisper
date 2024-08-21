defmodule PictureWhisperWeb.ImageLive.New do
  use PictureWhisperWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form, to_form(%{"prompt" => ""}))}
  end

  @impl true
  def handle_event("generate", %{"prompt" => prompt}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/images/generate?prompt=#{prompt}")}
  end
end
