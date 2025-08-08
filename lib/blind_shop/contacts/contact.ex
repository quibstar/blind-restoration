defmodule BlindShop.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :subject, :string
    field :message, :string
    # Honeypot fields
    field :website, :string
    field :company, :string
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :email, :phone, :subject, :message, :website, :company])
    |> validate_required([:name, :email, :subject, :message])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: "must be a valid email address"
    )
    |> validate_length(:message, min: 10, max: 5000)
    |> validate_inclusion(:subject, ["quote", "order_status", "general", "complaint", "business", "other"])
    |> validate_honeypot()
  end

  defp validate_honeypot(changeset) do
    website = get_change(changeset, :website)
    company = get_change(changeset, :company)

    if website not in [nil, ""] or company not in [nil, ""] do
      add_error(changeset, :base, "Invalid submission detected")
    else
      changeset
    end
  end
end