defmodule PictureWhisper.Images.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :prompt, :string
    field :url, :string
    belongs_to :user, PictureWhisper.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:prompt, :url, :user_id])
    |> validate_required([:prompt, :url, :user_id])
  end
end
