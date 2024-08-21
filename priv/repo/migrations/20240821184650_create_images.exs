defmodule PictureWhisper.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :prompt, :string, null: false
      add :url, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:images, [:user_id])
  end
end
