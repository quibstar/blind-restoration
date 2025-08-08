defmodule BlindShop.Repo.Migrations.CreateContactSubmissions do
  use Ecto.Migration

  def change do
    create table(:contact_submissions) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :phone, :string
      add :subject, :string, null: false
      add :message, :text, null: false
      add :user_agent, :string
      add :ip_address, :string
      add :status, :string, default: "pending", null: false
      add :responded_at, :utc_datetime
      
      timestamps(type: :utc_datetime)
    end
    
    create index(:contact_submissions, [:email])
    create index(:contact_submissions, [:status])
    create index(:contact_submissions, [:inserted_at])
    create index(:contact_submissions, [:subject])
  end
end
