defmodule PictureWhisperWeb.ImageController do
  use PictureWhisperWeb, :controller

  alias PictureWhisper.Images

  def generate(conn, %{"prompt" => prompt}) do
    user = conn.assigns.current_user
    api_key = user.openai_api_key

    if is_nil(api_key) do
      conn
      |> put_flash(:error, "OpenAI API key not set. Please update your settings.")
      |> redirect(to: ~p"/settings")
    else
      case Images.generate_image(prompt, api_key) do
        {:ok, image_url} ->
          case Images.save_image(image_url, prompt, user.id) do
            {:ok, image} ->
              conn
              |> put_flash(:info, "Image generated successfully.")
              |> redirect(to: ~p"/images/#{image.id}")

            {:error, reason} ->
              conn
              |> put_flash(:error, reason)
              |> redirect(to: ~p"/images/new")
          end

        {:error, reason} ->
          conn
          |> put_flash(:error, reason)
          |> redirect(to: ~p"/images/new")
      end
    end
  end
end
