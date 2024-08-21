defmodule PictureWhisperWeb.UploadsController do
  use PictureWhisperWeb, :controller

  def show(conn, %{"filename" => filename}) do
    uploads_dir = Path.join(["priv", "static", "uploads"])
    file_path = Path.join(uploads_dir, filename)

    if File.exists?(file_path) do
      send_file(conn, 200, file_path)
    else
      send_resp(conn, 404, "File not found")
    end
  end
end
