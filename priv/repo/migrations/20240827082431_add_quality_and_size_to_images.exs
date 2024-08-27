defmodule PictureWhisper.Repo.Migrations.AddQualityAndSizeToImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :quality, :string
      add :size, :string
    end
  end
end
