defmodule BlindShop.Contacts.ContactSubmission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_submissions" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :subject, :string
    field :message, :string
    field :user_agent, :string
    field :ip_address, :string
    field :status, :string, default: "pending"
    field :responded_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contact_submission, attrs) do
    contact_submission
    |> cast(attrs, [:name, :email, :phone, :subject, :message, :user_agent, :ip_address, :status, :responded_at])
    |> validate_required([:name, :email, :subject, :message])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> validate_inclusion(:subject, ["quote", "order_status", "general", "complaint", "business", "other"])
    |> validate_inclusion(:status, ["pending", "responded", "spam", "archived"])
    |> validate_length(:message, min: 10, max: 5000)
  end
end