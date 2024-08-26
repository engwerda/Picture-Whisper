defmodule PictureWhisperWeb.UploadsController do
  use PictureWhisperWeb, :controller

  def show(conn, %{"filename" => filename}) do
    uploads_dir = Path.join(["priv", "static", "uploads"])
    file_path = Path.join(uploads_dir, filename)

    if File.exists?(file_path) do
      content_type = MIME.from_path(file_path)
      conn
      |> put_resp_header("content-disposition", "inline")
      |> put_resp_content_type(content_type)
      |> send_file(200, file_path)
    else
      conn
      |> put_status(:not_found)
      |> text("File not found")
    end
  end
end
