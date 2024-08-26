defmodule PictureWhisper.Repo do
  use Ecto.Repo,
    otp_app: :picture_whisper,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
