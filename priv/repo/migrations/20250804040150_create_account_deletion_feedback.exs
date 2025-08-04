defmodule BlindShop.Repo.Migrations.CreateAccountDeletionFeedback do
  use Ecto.Migration

  def change do
    create table(:account_deletion_feedback) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :reason, :string
      add :satisfaction_rating, :integer
      add :service_rating, :integer
      add :recommend_rating, :integer
      add :comments, :text
      add :improvement_suggestions, :text
      
      timestamps(type: :utc_datetime)
    end

    create index(:account_deletion_feedback, [:user_id])
    create index(:account_deletion_feedback, [:inserted_at])
  end
end
