defmodule PictureWhisper.Images.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :prompt, :string
    field :url, :string
    field :quality, :string
    field :size, :string
    field :user_api_key, :string
    belongs_to :user, PictureWhisper.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:prompt, :url, :user_id, :quality, :size, :user_api_key])
    |> validate_required([:prompt, :url, :user_id, :quality, :size])
  end
end

