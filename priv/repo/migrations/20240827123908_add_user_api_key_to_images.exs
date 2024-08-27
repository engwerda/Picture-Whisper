defmodule PictureWhisper.Repo.Migrations.AddUserApiKeyToImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :user_api_key, :string
    end
  end
end
