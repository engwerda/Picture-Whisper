defmodule PictureWhisperWeb.ImageController do
  use PictureWhisperWeb, :controller

  alias PictureWhisper.Images

  def generate(conn, %{"prompt" => prompt}) do
    api_key = Application.get_env(:picture_whisper, :openai_api_key)
    current_user = conn.assigns.current_user

    if is_nil(api_key) do
      conn
      |> put_flash(:error, "OpenAI API key not set. Please check your application configuration.")
      |> redirect(to: ~p"/images/new")
    else
      case Images.generate_image(prompt, api_key) do
        {:ok, image_data} ->
          case Images.save_image(image_data, prompt, current_user.id) do
            {:ok, image} ->
              conn
              |> put_flash(:info, "Image generated successfully.")
              |> redirect(to: ~p"/images/#{image.id}")

            {:error, reason} ->
              conn
              |> put_flash(:error, "Failed to save image: #{reason}")
              |> redirect(to: ~p"/images/new")
          end

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to generate image: #{reason}")
          |> redirect(to: ~p"/images/new")
      end
    end
  end
end
