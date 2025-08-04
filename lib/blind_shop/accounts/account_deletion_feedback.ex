defmodule BlindShop.Accounts.AccountDeletionFeedback do
  use Ecto.Schema
  import Ecto.Changeset

  schema "account_deletion_feedback" do
    field :reason, :string
    field :satisfaction_rating, :integer
    field :service_rating, :integer
    field :recommend_rating, :integer
    field :comments, :string
    field :improvement_suggestions, :string

    belongs_to :user, BlindShop.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:user_id, :reason, :satisfaction_rating, :service_rating, :recommend_rating, :comments, :improvement_suggestions])
    |> validate_required([:user_id])
    |> validate_inclusion(:satisfaction_rating, 1..5)
    |> validate_inclusion(:service_rating, 1..5)
    |> validate_inclusion(:recommend_rating, 1..10)
    |> foreign_key_constraint(:user_id)
  end
end