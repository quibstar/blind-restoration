defmodule BlindShopWeb.AdminLive.ContactInquiries do
  use BlindShopWeb, :live_view

  alias BlindShop.Contacts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search_query, "")
     |> assign(:status_filter, "all")
     |> assign(:sort_by, "inserted_at")
     |> assign(:sort_order, "desc")
     |> assign(:page, 1)
     |> assign(:per_page, 20)
     |> assign(:selected_ids, MapSet.new())
     |> load_inquiries()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    search_query = Map.get(params, "search", "")
    status_filter = Map.get(params, "status", "all")
    sort_by = Map.get(params, "sort_by", "inserted_at")
    sort_order = Map.get(params, "sort_order", "desc")
    page = String.to_integer(Map.get(params, "page", "1"))

    {:noreply,
     socket
     |> assign(:search_query, search_query)
     |> assign(:status_filter, status_filter)
     |> assign(:sort_by, sort_by)
     |> assign(:sort_order, sort_order)
     |> assign(:page, page)
     |> assign(:selected_ids, MapSet.new())
     |> load_inquiries()}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_path(socket, %{search: query, page: 1})
     )}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_path(socket, %{status: status, page: 1})
     )}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    sort_order =
      if socket.assigns.sort_by == field and socket.assigns.sort_order == "asc" do
        "desc"
      else
        "asc"
      end

    {:noreply,
     push_patch(socket,
       to: build_path(socket, %{sort_by: field, sort_order: sort_order, page: 1})
     )}
  end

  @impl true
  def handle_event("select_inquiry", %{"id" => id}, socket) do
    inquiry_id = String.to_integer(id)
    selected_ids = 
      if MapSet.member?(socket.assigns.selected_ids, inquiry_id) do
        MapSet.delete(socket.assigns.selected_ids, inquiry_id)
      else
        MapSet.put(socket.assigns.selected_ids, inquiry_id)
      end

    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  @impl true
  def handle_event("select_all", _params, socket) do
    all_ids = MapSet.new(Enum.map(socket.assigns.pagination.submissions, & &1.id))
    
    selected_ids = 
      if MapSet.equal?(socket.assigns.selected_ids, all_ids) do
        MapSet.new()
      else
        all_ids
      end

    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  @impl true
  def handle_event("bulk_action", %{"action" => action}, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_ids)
    
    case selected_ids do
      [] ->
        {:noreply, put_flash(socket, :error, "Please select at least one inquiry.")}
      
      ids ->
        case action do
          "mark_responded" ->
            {count, _} = Contacts.bulk_update_status(ids, "responded")
            socket = 
              socket
              |> put_flash(:info, "Marked #{count} inquiries as responded.")
              |> assign(:selected_ids, MapSet.new())
              |> load_inquiries()
            {:noreply, socket}
            
          "mark_spam" ->
            {count, _} = Contacts.bulk_update_status(ids, "spam")
            socket = 
              socket
              |> put_flash(:info, "Marked #{count} inquiries as spam.")
              |> assign(:selected_ids, MapSet.new())
              |> load_inquiries()
            {:noreply, socket}
            
          "mark_pending" ->
            {count, _} = Contacts.bulk_update_status(ids, "pending")
            socket = 
              socket
              |> put_flash(:info, "Marked #{count} inquiries as pending.")
              |> assign(:selected_ids, MapSet.new())
              |> load_inquiries()
            {:noreply, socket}
            
          _ ->
            {:noreply, put_flash(socket, :error, "Invalid action.")}
        end
    end
  end

  @impl true
  def handle_event("update_status", %{"id" => id, "status" => status}, socket) do
    inquiry = Contacts.get_contact_submission!(id)
    
    case Contacts.update_contact_status(inquiry, status) do
      {:ok, _inquiry} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Status updated successfully.")
         |> load_inquiries()}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update status.")}
    end
  end

  @impl true
  def handle_event("navigate_page", %{"page" => page}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_path(socket, %{page: page})
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Contact Inquiries</h1>
        <p class="mt-2 text-gray-600">Manage and respond to customer inquiries</p>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <div class="flex flex-col md:flex-row gap-4 items-end">
          <!-- Search -->
          <div class="flex-1">
            <.form for={%{}} phx-submit="search" class="flex gap-2">
              <input 
                type="text" 
                name="search[query]" 
                value={@search_query}
                placeholder="Search by name, email, or message..."
                class="input input-bordered flex-1"
              />
              <button type="submit" class="btn btn-primary">Search</button>
            </.form>
          </div>

          <!-- Status Filter -->
          <div class="form-control">
            <label class="label">
              <span class="label-text">Status Filter</span>
            </label>
            <select 
              class="select select-bordered"
              phx-change="filter_status"
              name="status"
            >
              <option value="all" selected={@status_filter == "all"}>All Status</option>
              <option value="pending" selected={@status_filter == "pending"}>Pending</option>
              <option value="responded" selected={@status_filter == "responded"}>Responded</option>
              <option value="spam" selected={@status_filter == "spam"}>Spam</option>
              <option value="archived" selected={@status_filter == "archived"}>Archived</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Bulk Actions -->
      <div :if={MapSet.size(@selected_ids) > 0} class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
        <div class="flex items-center justify-between">
          <div>
            <span class="font-medium"><%= MapSet.size(@selected_ids) %> inquiry(ies) selected</span>
          </div>
          <div class="flex gap-2">
            <button 
              phx-click="bulk_action" 
              phx-value-action="mark_responded" 
              class="btn btn-sm btn-success"
            >
              Mark Responded
            </button>
            <button 
              phx-click="bulk_action" 
              phx-value-action="mark_pending" 
              class="btn btn-sm btn-warning"
            >
              Mark Pending
            </button>
            <button 
              phx-click="bulk_action" 
              phx-value-action="mark_spam" 
              class="btn btn-sm btn-error"
            >
              Mark Spam
            </button>
          </div>
        </div>
      </div>

      <!-- Inquiries Table -->
      <div class="bg-white shadow rounded-lg overflow-hidden">
        <table class="table table-zebra w-full">
          <thead>
            <tr>
              <th>
                <input 
                  type="checkbox" 
                  class="checkbox"
                  phx-click="select_all"
                  checked={MapSet.size(@selected_ids) > 0 and 
                           MapSet.equal?(@selected_ids, MapSet.new(Enum.map(@pagination.submissions, & &1.id)))}
                />
              </th>
              <th>
                <button 
                  phx-click="sort" 
                  phx-value-field="inserted_at" 
                  class="flex items-center gap-1 hover:text-primary"
                >
                  Date
                  <.sort_icon field="inserted_at" current_field={@sort_by} current_order={@sort_order} />
                </button>
              </th>
              <th>
                <button 
                  phx-click="sort" 
                  phx-value-field="name" 
                  class="flex items-center gap-1 hover:text-primary"
                >
                  Name
                  <.sort_icon field="name" current_field={@sort_by} current_order={@sort_order} />
                </button>
              </th>
              <th>
                <button 
                  phx-click="sort" 
                  phx-value-field="email" 
                  class="flex items-center gap-1 hover:text-primary"
                >
                  Email
                  <.sort_icon field="email" current_field={@sort_by} current_order={@sort_order} />
                </button>
              </th>
              <th>
                <button 
                  phx-click="sort" 
                  phx-value-field="subject" 
                  class="flex items-center gap-1 hover:text-primary"
                >
                  Subject
                  <.sort_icon field="subject" current_field={@sort_by} current_order={@sort_order} />
                </button>
              </th>
              <th>
                <button 
                  phx-click="sort" 
                  phx-value-field="status" 
                  class="flex items-center gap-1 hover:text-primary"
                >
                  Status
                  <.sort_icon field="status" current_field={@sort_by} current_order={@sort_order} />
                </button>
              </th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={inquiry <- @pagination.submissions}>
              <td>
                <input 
                  type="checkbox" 
                  class="checkbox"
                  phx-click="select_inquiry"
                  phx-value-id={inquiry.id}
                  checked={MapSet.member?(@selected_ids, inquiry.id)}
                />
              </td>
              <td>
                <div class="text-sm">
                  <%= Calendar.strftime(inquiry.inserted_at, "%m/%d/%Y") %>
                  <br />
                  <span class="text-gray-500">
                    <%= Calendar.strftime(inquiry.inserted_at, "%I:%M %p") %>
                  </span>
                </div>
              </td>
              <td class="font-medium"><%= inquiry.name %></td>
              <td>
                <a href={"mailto:#{inquiry.email}"} class="text-blue-600 hover:underline">
                  <%= inquiry.email %>
                </a>
              </td>
              <td>
                <div>
                  <span class="font-medium"><%= format_subject(inquiry.subject) %></span>
                  <div class="text-sm text-gray-500 truncate max-w-xs">
                    <%= String.slice(inquiry.message, 0, 100) %><%= if String.length(inquiry.message) > 100, do: "..." %>
                  </div>
                </div>
              </td>
              <td>
                <.status_badge status={inquiry.status} />
              </td>
              <td>
                <div class="flex gap-1">
                  <.link 
                    navigate={~p"/admin/contact-inquiries/#{inquiry.id}"} 
                    class="btn btn-sm btn-outline"
                  >
                    View
                  </.link>
                  <div class="dropdown dropdown-end">
                    <label tabindex="0" class="btn btn-sm btn-square btn-ghost">
                      <.icon name="hero-ellipsis-horizontal" class="w-4 h-4" />
                    </label>
                    <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-40">
                      <li :if={inquiry.status != "responded"}>
                        <button 
                          phx-click="update_status" 
                          phx-value-id={inquiry.id} 
                          phx-value-status="responded"
                          class="text-success"
                        >
                          Mark Responded
                        </button>
                      </li>
                      <li :if={inquiry.status != "pending"}>
                        <button 
                          phx-click="update_status" 
                          phx-value-id={inquiry.id} 
                          phx-value-status="pending"
                          class="text-warning"
                        >
                          Mark Pending
                        </button>
                      </li>
                      <li :if={inquiry.status != "spam"}>
                        <button 
                          phx-click="update_status" 
                          phx-value-id={inquiry.id} 
                          phx-value-status="spam"
                          class="text-error"
                        >
                          Mark Spam
                        </button>
                      </li>
                    </ul>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- Empty State -->
        <div :if={@pagination.submissions == []} class="text-center py-12">
          <.icon name="hero-inbox" class="w-16 h-16 text-gray-300 mx-auto mb-4" />
          <h3 class="text-lg font-medium text-gray-900 mb-2">No inquiries found</h3>
          <p class="text-gray-500">Try adjusting your search or filters.</p>
        </div>
      </div>

      <!-- Pagination -->
      <.pagination 
        :if={@pagination.total_pages > 1}
        current_page={@pagination.page}
        total_pages={@pagination.total_pages}
        total_count={@pagination.total_count}
      />
    </div>
    """
  end

  # Helper functions

  defp load_inquiries(socket) do
    opts = [
      page: socket.assigns.page,
      per_page: socket.assigns.per_page,
      sort_by: socket.assigns.sort_by,
      sort_order: socket.assigns.sort_order,
      search: (if socket.assigns.search_query != "", do: socket.assigns.search_query),
      status: (if socket.assigns.status_filter != "all", do: socket.assigns.status_filter)
    ]
    
    pagination = Contacts.list_contact_submissions_paginated(opts)
    assign(socket, :pagination, pagination)
  end

  defp build_path(socket, overrides \\ %{}) do
    params = %{
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.status_filter,
      "sort_by" => socket.assigns.sort_by,
      "sort_order" => socket.assigns.sort_order,
      "page" => to_string(socket.assigns.page)
    }
    |> Map.merge(Enum.into(overrides, %{}, fn {k, v} -> {to_string(k), to_string(v)} end))
    |> Enum.reject(fn {_k, v} -> v == "" or v == "all" or v == "1" end)
    |> Enum.into(%{})

    case params do
      empty when map_size(empty) == 0 -> ~p"/admin/contact-inquiries"
      _ -> ~p"/admin/contact-inquiries?#{params}"
    end
  end

  defp format_subject("quote"), do: "Quote Request"
  defp format_subject("order_status"), do: "Order Status"
  defp format_subject("general"), do: "General Inquiry"
  defp format_subject("complaint"), do: "Complaint"
  defp format_subject("business"), do: "Business Inquiry"
  defp format_subject("other"), do: "Other"
  defp format_subject(subject), do: subject

  # Component functions

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "badge badge-sm",
      @status == "pending" && "badge-warning",
      @status == "responded" && "badge-success", 
      @status == "spam" && "badge-error",
      @status == "archived" && "badge-ghost"
    ]}>
      <%= String.capitalize(@status) %>
    </span>
    """
  end

  defp sort_icon(assigns) do
    ~H"""
    <span :if={@field == @current_field}>
      <.icon :if={@current_order == "asc"} name="hero-chevron-up" class="w-3 h-3" />
      <.icon :if={@current_order == "desc"} name="hero-chevron-down" class="w-3 h-3" />
    </span>
    """
  end

  defp pagination(assigns) do
    ~H"""
    <div class="flex items-center justify-between mt-6">
      <div class="text-sm text-gray-700">
        Showing <%= (@current_page - 1) * 20 + 1 %> to <%= min(@current_page * 20, @total_count) %> of <%= @total_count %> results
      </div>
      <div class="btn-group">
        <button 
          :if={@current_page > 1}
          phx-click="navigate_page" 
          phx-value-page={@current_page - 1}
          class="btn btn-sm"
        >
          Previous
        </button>
        
        <span class="btn btn-sm btn-active">
          Page <%= @current_page %> of <%= @total_pages %>
        </span>
        
        <button 
          :if={@current_page < @total_pages}
          phx-click="navigate_page" 
          phx-value-page={@current_page + 1}
          class="btn btn-sm"
        >
          Next
        </button>
      </div>
    </div>
    """
  end
end