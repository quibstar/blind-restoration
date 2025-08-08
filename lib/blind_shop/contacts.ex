defmodule BlindShop.Contacts do
  @moduledoc """
  The Contacts context for managing contact submissions and inquiries.
  """

  import Ecto.Query, warn: false
  alias BlindShop.Repo

  alias BlindShop.Contacts.ContactSubmission

  @doc """
  Returns the list of contact submissions with optional filtering and sorting.
  """
  def list_contact_submissions(opts \\ []) do
    ContactSubmission
    |> apply_filters(opts)
    |> apply_sorting(opts)
    |> Repo.all()
  end

  @doc """
  Returns paginated contact submissions.
  """
  def list_contact_submissions_paginated(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    
    query = 
      ContactSubmission
      |> apply_filters(opts)
      |> apply_sorting(opts)
    
    total_count = Repo.aggregate(query, :count, :id)
    
    submissions = 
      query
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> Repo.all()
    
    total_pages = ceil(total_count / per_page)
    
    %{
      submissions: submissions,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      has_prev: page > 1,
      has_next: page < total_pages
    }
  end

  @doc """
  Gets a single contact submission.
  """
  def get_contact_submission!(id), do: Repo.get!(ContactSubmission, id)

  @doc """
  Creates a contact submission.
  """
  def create_contact_submission(attrs \\ %{}) do
    %ContactSubmission{}
    |> ContactSubmission.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a contact submission.
  """
  def update_contact_submission(%ContactSubmission{} = contact_submission, attrs) do
    contact_submission
    |> ContactSubmission.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the status of a contact submission.
  """
  def update_contact_status(%ContactSubmission{} = contact_submission, status) do
    attrs = %{status: status}
    
    attrs = 
      if status == "responded" and is_nil(contact_submission.responded_at) do
        Map.put(attrs, :responded_at, DateTime.utc_now())
      else
        attrs
      end
    
    update_contact_submission(contact_submission, attrs)
  end

  @doc """
  Deletes a contact submission.
  """
  def delete_contact_submission(%ContactSubmission{} = contact_submission) do
    Repo.delete(contact_submission)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking contact submission changes.
  """
  def change_contact_submission(%ContactSubmission{} = contact_submission, attrs \\ %{}) do
    ContactSubmission.changeset(contact_submission, attrs)
  end

  @doc """
  Gets contact submission statistics.
  """
  def get_contact_stats do
    base_query = from(c in ContactSubmission)
    
    %{
      total: Repo.aggregate(base_query, :count),
      pending: base_query |> where([c], c.status == "pending") |> Repo.aggregate(:count),
      responded: base_query |> where([c], c.status == "responded") |> Repo.aggregate(:count),
      spam: base_query |> where([c], c.status == "spam") |> Repo.aggregate(:count),
      today: base_query |> where([c], fragment("DATE(?) = CURRENT_DATE", c.inserted_at)) |> Repo.aggregate(:count),
      this_week: base_query |> where([c], c.inserted_at >= ^beginning_of_week()) |> Repo.aggregate(:count)
    }
  end

  @doc """
  Marks multiple submissions as a specific status.
  """
  def bulk_update_status(ids, status) when is_list(ids) do
    attrs = %{status: status}
    
    attrs = 
      if status == "responded" do
        Map.put(attrs, :responded_at, DateTime.utc_now())
      else
        attrs
      end
    
    from(c in ContactSubmission, where: c.id in ^ids)
    |> Repo.update_all(set: Map.to_list(attrs))
  end

  # Private functions

  defp apply_filters(query, opts) do
    query
    |> filter_by_status(opts[:status])
    |> filter_by_search(opts[:search])
    |> filter_by_subject(opts[:subject])
    |> filter_by_date_range(opts[:date_from], opts[:date_to])
  end

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status) when is_binary(status) do
    where(query, [c], c.status == ^status)
  end

  defp filter_by_search(query, nil), do: query
  defp filter_by_search(query, ""), do: query
  defp filter_by_search(query, search_term) when is_binary(search_term) do
    search_pattern = "%#{search_term}%"
    
    where(query, [c], 
      ilike(c.name, ^search_pattern) or 
      ilike(c.email, ^search_pattern) or 
      ilike(c.message, ^search_pattern)
    )
  end

  defp filter_by_subject(query, nil), do: query
  defp filter_by_subject(query, subject) when is_binary(subject) do
    where(query, [c], c.subject == ^subject)
  end

  defp filter_by_date_range(query, nil, nil), do: query
  defp filter_by_date_range(query, date_from, nil) when not is_nil(date_from) do
    where(query, [c], c.inserted_at >= ^date_from)
  end
  defp filter_by_date_range(query, nil, date_to) when not is_nil(date_to) do
    where(query, [c], c.inserted_at <= ^date_to)
  end
  defp filter_by_date_range(query, date_from, date_to) when not is_nil(date_from) and not is_nil(date_to) do
    where(query, [c], c.inserted_at >= ^date_from and c.inserted_at <= ^date_to)
  end

  defp apply_sorting(query, opts) do
    sort_by = Keyword.get(opts, :sort_by, "inserted_at")
    sort_order = Keyword.get(opts, :sort_order, "desc")
    
    case {sort_by, sort_order} do
      {"inserted_at", "desc"} -> order_by(query, [c], desc: c.inserted_at)
      {"inserted_at", "asc"} -> order_by(query, [c], asc: c.inserted_at)
      {"name", "desc"} -> order_by(query, [c], desc: c.name)
      {"name", "asc"} -> order_by(query, [c], asc: c.name)
      {"email", "desc"} -> order_by(query, [c], desc: c.email)
      {"email", "asc"} -> order_by(query, [c], asc: c.email)
      {"subject", "desc"} -> order_by(query, [c], desc: c.subject)
      {"subject", "asc"} -> order_by(query, [c], asc: c.subject)
      {"status", "desc"} -> order_by(query, [c], desc: c.status)
      {"status", "asc"} -> order_by(query, [c], asc: c.status)
      _ -> order_by(query, [c], desc: c.inserted_at)
    end
  end

  defp beginning_of_week do
    today = Date.utc_today()
    days_to_subtract = Date.day_of_week(today) - 1
    Date.add(today, -days_to_subtract)
    |> DateTime.new!(~T[00:00:00])
  end
end