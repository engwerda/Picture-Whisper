defmodule PictureWhisper.Images do
  @moduledoc """
  The Images context.
  """

  import Ecto.Query, warn: false
  alias PictureWhisper.Repo

  alias PictureWhisper.Images.Image

  @doc """
  Generates an image using OpenAI's DALL-E API with the user's API key.
  """
  def generate_image(prompt, user) do
    case user.openai_api_key do
      nil ->
        {:error, "OpenAI API key not set for user"}

      api_key ->
        IO.puts("Generating image with prompt: #{prompt}")

        # Increase timeout to 60 seconds
        config_override = %OpenAI.Config{
          api_key: api_key,
          http_options: [recv_timeout: 60_000]
        }

        case OpenAI.images_generations(
               [
                 prompt: prompt,
                 n: 1,
                 size: "1024x1024",
                 response_format: "url"
               ],
               config_override
             ) do
          {:ok, %{data: [%{"url" => image_url} | _]}} ->
            IO.puts("Image generated successfully")
            {:ok, image_url}

          {:error, %HTTPoison.Error{reason: :timeout}} ->
            IO.puts("Image generation timed out")
            {:error, :timeout}

          {:error, error} ->
            IO.puts("Failed to generate image: #{inspect(error)}")
            {:error, "Failed to generate image: #{inspect(error)}"}
        end
    end
  end

  @doc """
  Saves an image locally.
  """
  def save_image(image_url, prompt, user_id) do
    with {:ok, %{body: image_data}} <- HTTPoison.get(image_url),
         file_name = "#{:crypto.strong_rand_bytes(16) |> Base.url_encode64()}.png",
         uploads_dir = Path.join(["priv", "static", "uploads"]),
         :ok <- File.mkdir_p(uploads_dir),
         file_path = Path.join(uploads_dir, file_name),
         :ok <- File.write(file_path, image_data),
         full_url = "#{PictureWhisperWeb.Endpoint.url()}/uploads/#{file_name}",
         attrs = %{
           prompt: prompt,
           url: full_url,
           user_id: user_id
         },
         {:ok, image} <- create_image(attrs) do
      {:ok, image}
    else
      {:error, reason} -> {:error, "Failed to save image: #{inspect(reason)}"}
    end
  end

  @doc """
  Returns the list of images for a given user.

  ## Examples

      iex> list_images(user)
      [%Image{}, ...]

  """
  def list_images(user) do
    Image
    |> where(user_id: ^user.id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single image.

  Raises `Ecto.NoResultsError` if the Image does not exist.

  ## Examples

      iex> get_image!(123)
      %Image{}

      iex> get_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_image!(id), do: Repo.get!(Image, id)

  @doc """
  Creates an image.

  ## Examples

      iex> create_image(%{field: value})
      {:ok, %Image{}}

      iex> create_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_image(attrs \\ %{}) do
    %Image{}
    |> Image.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an image.

  ## Examples

      iex> update_image(image, %{field: new_value})
      {:ok, %Image{}}

      iex> update_image(image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_image(%Image{} = image, attrs) do
    image
    |> Image.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an image.

  ## Examples

      iex> delete_image(image)
      {:ok, %Image{}}

      iex> delete_image(image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_image(%Image{} = image) do
    Repo.delete(image)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking image changes.

  ## Examples

      iex> change_image(image)
      %Ecto.Changeset{data: %Image{}}

  """
  def change_image(%Image{} = image, attrs \\ %{}) do
    Image.changeset(image, attrs)
  end
end
