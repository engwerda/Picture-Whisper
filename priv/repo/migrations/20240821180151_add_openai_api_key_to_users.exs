defmodule PictureWhisper.Repo.Migrations.AddOpenaiApiKeyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :openai_api_key, :string
    end
  end
end
