defmodule PictureWhisper.Images do
  alias Phoenix.PubSub
  alias ExAws.S3

  def subscribe(topic) do
    PubSub.subscribe(PictureWhisper.PubSub, topic)
  end

  @bucket "picture-whisper-images"
  @uploads_directory Application.compile_env(:picture_whisper, :uploads_directory, "priv/static/uploads")
  @moduledoc """
  The Images context.
  """

  import Ecto.Query, warn: false
  alias PictureWhisper.Repo

  alias PictureWhisper.Images.Image

  @max_global_key_images 10
  def max_global_key_images, do: @max_global_key_images


  @doc """
  Returns the total count of images for a given user.

  ## Examples

      iex> count_images(user)
      15

  """
  def count_images(user) do
    Image
    |> where(user_id: ^user.id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns a list of images for a given user, paginated.

  ## Examples

      iex> list_images(user, 1, 10)
      [%Image{}, ...]

  """
  def list_images(user, page, per_page) do
    Image
    |> where(user_id: ^user.id)
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
  end

  @doc """
  Creates an image.
  """
  def create_image(attrs \\ %{}) do
    %Image{}
    |> Image.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Generates a unique file name with the given extension.
  """
  def generate_file_name(extension) do
    "#{Ecto.UUID.generate()}.#{extension}"
  end

  @doc """
  Gets the file extension based on the content type.
  """
  def get_file_extension(content_type) do
    case content_type do
      "image/png" -> "png"
      "image/jpeg" -> "jpg"
      # Default to png if content type is unknown
      _ -> "png"
    end
  end

  @doc """
  Extracts the content type from the response headers.
  """
  def get_content_type(headers) do
    {_, content_type} = List.keyfind(headers, "Content-Type", 0)
    content_type
  end

  @doc """
  Generates an image using OpenAI's DALL-E API with the user's API key.
  """
  def generate_image(prompt, size, quality, user) do
    # Convert size name to dimensions if necessary
    size =
      case size do
        "Square" -> "1024x1024"
        "Portrait" -> "1024x1792"
        "Landscape" -> "1792x1024"
        # If it's already a dimension string, use it as is
        _ -> size
      end

    api_key = get_api_key(user)
    api_key = if api_key, do: PictureWhisper.Encryption.decrypt(api_key), else: nil
    is_global_key = api_key == Application.get_env(:picture_whisper, :openai)[:global_api_key]

    cond do
      is_global_key && quality != "standard" ->
        {:error, "Standard quality only allowed with global API key"}

      is_global_key && count_user_global_key_images(user) >= @max_global_key_images ->
        {:error, "Maximum number of images with global API key reached"}

      true ->
        IO.puts("Generating image with prompt: #{prompt}, size: #{size}, quality: #{quality}")

        # Increase timeout to 90 seconds
        config_override = %OpenAI.Config{
          api_key: api_key,
          http_options: [recv_timeout: 90_000]
        }

        case OpenAI.images_generations(
               [
                 prompt: prompt,
                 n: 1,
                 size: size,
                 response_format: "url",
                 model: "dall-e-3",
                 quality: quality
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

  defp get_api_key(user) do
    case user.openai_api_key do
      nil ->
        Application.get_env(:picture_whisper, :openai)[:global_api_key]

      encrypted_api_key ->
        encrypted_api_key
    end
  end

  defp count_user_global_key_images(user) do
    Image
    |> where(user_id: ^user.id)
    |> where([i], is_nil(i.user_api_key))
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the number of free images used and the number of free images left for a user.
  """
  def get_free_image_stats(user) do
    used = count_user_global_key_images(user)
    left = @max_global_key_images - used
    {used, left}
  end

  @doc """
  Generates an image asynchronously using OpenAI's DALL-E API with the user's API key.
  """
  def generate_image_async(prompt, size, quality, user, generation_id) do
    Task.start(fn ->
      result = generate_image(prompt, size, quality, user)

      case result do
        {:ok, image_url} ->
          {:ok, image} = save_image(image_url, prompt, user, quality, size)

          Phoenix.PubSub.broadcast(
            PictureWhisper.PubSub,
            "user_images:#{user.id}",
            {:image_generated, generation_id, {:ok, image}}
          )

        {:error, reason} ->
          Phoenix.PubSub.broadcast(
            PictureWhisper.PubSub,
            "user_images:#{user.id}",
            {:image_generated, generation_id, {:error, reason}}
          )
      end
    end)
  end

  @doc """
  Saves an image to S3 in production or local file system in development.
  """
  def save_image(image_url, prompt, user, quality, size) do
    with {:ok, %{body: image_data, headers: headers}} <- HTTPoison.get(image_url),
         content_type = get_content_type(headers),
         file_extension = get_file_extension(content_type),
         file_name = generate_file_name(file_extension),
         {:ok, full_url} <- save_image_file(file_name, image_data),
         attrs = %{
           prompt: prompt,
           url: full_url,
           user_id: user.id,
           quality: quality,
           size: size,
           user_api_key: if(user.openai_api_key, do: "used", else: nil)
         },
         {:ok, image} <- create_image(attrs) do
      {:ok, image}
    else
      {:error, reason} -> {:error, "Failed to save image: #{inspect(reason)}"}
    end
  end

  defp save_image_file(file_name, image_data) do
    if Mix.env() == :prod do
      case S3.put_object(@bucket, file_name, image_data) |> ExAws.request() do
        {:ok, _} ->
          {:ok, "https://#{@bucket}.fly.storage.tigris.dev/#{file_name}"}
        error ->
          error
      end
    else
      file_path = Path.join(@uploads_directory, file_name)
      with :ok <- File.write(file_path, image_data) do
        {:ok, "/uploads/#{file_name}"}
      end
    end
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
  Deletes an image from S3 in production or local file system in development and broadcasts the deletion.

  ## Examples

      iex> delete_image_and_broadcast(image)
      {:ok, %Image{}}

  """
  def delete_image_and_broadcast(%Image{} = image) do
    with :ok <- delete_image_file(image),
         {:ok, deleted_image} <- Repo.delete(image) do
      Phoenix.PubSub.broadcast(
        PictureWhisper.PubSub,
        "user_images:#{image.user_id}",
        {:image_deleted, deleted_image.id}
      )

      {:ok, deleted_image}
    else
      error -> error
    end
  end

  defp delete_image_file(image) do
    if Mix.env() == :prod do
      file_name = URI.parse(image.url).path |> String.trim_leading("/")
      case S3.delete_object(@bucket, file_name) |> ExAws.request() do
        {:ok, _} -> :ok
        error -> error
      end
    else
      file_path = Path.join(@uploads_directory, Path.basename(image.url))
      case File.rm(file_path) do
        :ok -> :ok
        {:error, :enoent} -> :ok  # File doesn't exist, consider it deleted
        error -> error
      end
    end
  end

  # ... (rest of the existing functions remain unchanged)
end
