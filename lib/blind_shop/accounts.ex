defmodule BlindShop.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias BlindShop.Repo

  alias BlindShop.Accounts.{User, UserToken, UserNotifier, AccountDeletionFeedback}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for registering a user, including first and last name.

  See `BlindShop.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(user, attrs \\ %{}, opts \\ []) do
    User.registration_changeset(user, attrs, opts)
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `BlindShop.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `BlindShop.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  ## Account Deletion

  @doc """
  Soft deletes a user account by anonymizing PII and marking as deleted.
  
  This preserves business records (orders, payments) while removing personal information
  to comply with privacy requirements. Orders remain for business/legal purposes but
  are associated with an anonymized user.
  
  ## Examples
  
      iex> delete_user_account(user)
      {:ok, %User{}}

      iex> delete_user_account(user)
      {:error, %Ecto.Changeset{}}
  """
  def delete_user_account(%User{} = user) do
    Repo.transact(fn ->
      # Anonymize the user's PII
      anonymized_attrs = %{
        email: "deleted_user_#{user.id}@deleted.blindrestoration.com",
        first_name: "Deleted",
        last_name: "User",
        deleted_at: DateTime.utc_now(:second)
      }

      changeset = 
        user
        |> User.changeset(anonymized_attrs)
        |> put_change(:hashed_password, nil)

      with {:ok, updated_user} <- Repo.update(changeset) do
        # Delete all authentication tokens
        Repo.delete_all(from(t in UserToken, where: t.user_id == ^user.id))
        
        {:ok, updated_user}
      end
    end)
  end

  @doc """
  Hard deletes a user account and all associated data.
  
  WARNING: This removes all traces of the user including order history.
  Use only when explicitly requested by user and you understand the legal implications.
  
  ## Examples
  
      iex> hard_delete_user_account(user)
      {:ok, %User{}}
  """
  def hard_delete_user_account(%User{} = user) do
    Repo.transact(fn ->
      # Delete all associated data first (due to foreign key constraints)
      Repo.delete_all(from(t in UserToken, where: t.user_id == ^user.id))
      
      # Note: Orders will need to be handled based on your business requirements
      # You might want to either:
      # 1. Delete orders (loses business records)
      # 2. Keep orders but set user_id to nil (orphaned orders)
      # 3. Transfer orders to a "deleted user" account
      
      # For now, we'll prevent hard delete if user has orders
      orders_count = Repo.aggregate(from(o in "orders", where: o.user_id == ^user.id), :count, :id)
      
      if orders_count > 0 do
        {:error, :has_orders}
      else
        Repo.delete(user)
      end
    end)
  end

  @doc """
  Checks if a user account is deleted (soft deleted).
  """
  def user_deleted?(%User{deleted_at: nil}), do: false
  def user_deleted?(%User{deleted_at: deleted_at}) when not is_nil(deleted_at), do: true

  @doc """
  Gets all active (non-deleted) users.
  """
  def list_active_users do
    Repo.all(from(u in User, where: is_nil(u.deleted_at)))
  end

  @doc """
  Filters out deleted users from authentication queries.
  """
  def get_active_user_by_email(email) do
    Repo.one(from(u in User, where: u.email == ^email and is_nil(u.deleted_at)))
  end

  def get_active_user_by_session_token(token) do
    {encoded_token, user_token} = UserToken.verify_session_token_query(token)

    Repo.one(
      from(ut in UserToken,
        join: u in User,
        on: ut.user_id == u.id,
        where: ut.token == ^encoded_token and ut.context == "session" and is_nil(u.deleted_at),
        select: u
      )
    )
  end

  ## Account Deletion Feedback

  @doc """
  Creates a changeset for account deletion feedback.
  """
  def change_account_deletion_feedback(%AccountDeletionFeedback{} = feedback, attrs \\ %{}) do
    AccountDeletionFeedback.changeset(feedback, attrs)
  end

  @doc """
  Saves account deletion feedback before deleting the account.
  """
  def create_account_deletion_feedback(attrs \\ %{}) do
    %AccountDeletionFeedback{}
    |> AccountDeletionFeedback.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a user account with optional feedback collection.
  
  If feedback_attrs are provided, saves the feedback before deletion.
  """
  def delete_user_account_with_feedback(%User{} = user, feedback_attrs \\ %{}) do
    Repo.transact(fn ->
      # Save feedback if provided
      if feedback_attrs != %{} do
        feedback_attrs = Map.put(feedback_attrs, :user_id, user.id)
        case create_account_deletion_feedback(feedback_attrs) do
          {:ok, _feedback} -> :ok
          {:error, _reason} -> :ok # Don't fail deletion if feedback fails
        end
      end

      # Proceed with account deletion
      case delete_user_account(user) do
        {:ok, deleted_user} -> {:ok, deleted_user}
        {:error, reason} -> {:error, reason}
      end
    end)
  end
end
