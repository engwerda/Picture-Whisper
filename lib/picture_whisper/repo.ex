defmodule PictureWhisper.Repo do
  use Ecto.Repo,
    otp_app: :picture_whisper,
    adapter: Ecto.Adapters.Postgres
end
