defmodule BlindShopWeb.AdminLive.ContactInquiryDetail do
  use BlindShopWeb, :live_view

  alias BlindShop.Contacts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    inquiry = Contacts.get_contact_submission!(id)
    
    {:ok,
     socket
     |> assign(:inquiry, inquiry)
     |> assign(:page_title, "Contact Inquiry ##{inquiry.id}")}
  end

  @impl true
  def handle_event("update_status", %{"status" => status}, socket) do
    case Contacts.update_contact_status(socket.assigns.inquiry, status) do
      {:ok, updated_inquiry} ->
        {:noreply,
         socket
         |> assign(:inquiry, updated_inquiry)
         |> put_flash(:info, "Status updated to #{status} successfully.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update status.")}
    end
  end

  @impl true
  def handle_event("delete_inquiry", _params, socket) do
    case Contacts.delete_contact_submission(socket.assigns.inquiry) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contact inquiry deleted successfully.")
         |> push_navigate(to: ~p"/admin/contact-inquiries")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete inquiry.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-8">
      <!-- Header -->
      <div class="flex items-center justify-between mb-8">
        <div>
          <.link navigate={~p"/admin/contact-inquiries"} class="text-sm text-blue-600 hover:underline mb-2 inline-block">
            ← Back to Contact Inquiries
          </.link>
          <h1 class="text-3xl font-bold text-gray-900">
            Contact Inquiry #<%= @inquiry.id %>
          </h1>
          <p class="text-gray-600">
            Submitted on <%= Calendar.strftime(@inquiry.inserted_at, "%B %d, %Y at %I:%M %p") %>
          </p>
        </div>
        <div class="flex gap-3">
          <.status_dropdown inquiry={@inquiry} />
          <button 
            phx-click="delete_inquiry" 
            data-confirm="Are you sure you want to delete this inquiry? This action cannot be undone."
            class="btn btn-error btn-sm"
          >
            <.icon name="hero-trash" class="w-4 h-4" />
            Delete
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Message -->
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Message</h2>
            <div class="bg-gray-50 rounded-lg p-4">
              <p class="whitespace-pre-wrap text-gray-900"><%= @inquiry.message %></p>
            </div>
          </div>

          <!-- Quick Actions -->
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
            <div class="flex flex-wrap gap-3">
              <a 
                href={"mailto:#{@inquiry.email}?subject=Re: #{format_subject(@inquiry.subject)}"} 
                class="btn btn-primary btn-sm"
              >
                <.icon name="hero-envelope" class="w-4 h-4 mr-2" />
                Reply via Email
              </a>
              
              <a :if={@inquiry.phone && @inquiry.phone != ""} 
                href={"tel:#{@inquiry.phone}"} 
                class="btn btn-outline btn-sm"
              >
                <.icon name="hero-phone" class="w-4 h-4 mr-2" />
                Call
              </a>
              
              <button 
                :if={@inquiry.status == "pending"}
                phx-click="update_status" 
                phx-value-status="responded" 
                class="btn btn-success btn-sm"
              >
                <.icon name="hero-check" class="w-4 h-4 mr-2" />
                Mark as Responded
              </button>
              
              <button 
                :if={@inquiry.status != "spam"}
                phx-click="update_status" 
                phx-value-status="spam" 
                class="btn btn-error btn-sm"
              >
                <.icon name="hero-no-symbol" class="w-4 h-4 mr-2" />
                Mark as Spam
              </button>
            </div>
          </div>

          <!-- Response Templates (Future Enhancement) -->
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Response Templates</h2>
            <div class="text-center py-8 text-gray-500">
              <.icon name="hero-document-text" class="w-12 h-12 mx-auto mb-2 text-gray-300" />
              <p>Response templates coming soon!</p>
              <p class="text-sm">Quick replies for common inquiries</p>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Contact Information -->
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Contact Information</h2>
            <div class="space-y-3">
              <div>
                <label class="text-sm font-medium text-gray-500">Name</label>
                <p class="text-gray-900"><%= @inquiry.name %></p>
              </div>
              
              <div>
                <label class="text-sm font-medium text-gray-500">Email</label>
                <p>
                  <a href={"mailto:#{@inquiry.email}"} class="text-blue-600 hover:underline">
                    <%= @inquiry.email %>
                  </a>
                </p>
              </div>
              
              <div :if={@inquiry.phone && @inquiry.phone != ""}>
                <label class="text-sm font-medium text-gray-500">Phone</label>
                <p>
                  <a href={"tel:#{@inquiry.phone}"} class="text-blue-600 hover:underline">
                    <%= @inquiry.phone %>
                  </a>
                </p>
              </div>
              
              <div>
                <label class="text-sm font-medium text-gray-500">Subject</label>
                <p class="text-gray-900"><%= format_subject(@inquiry.subject) %></p>
              </div>
            </div>
          </div>

          <!-- Status & Timestamps -->
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Status & Timeline</h2>
            <div class="space-y-3">
              <div>
                <label class="text-sm font-medium text-gray-500">Current Status</label>
                <div class="mt-1">
                  <.status_badge status={@inquiry.status} />
                </div>
              </div>
              
              <div>
                <label class="text-sm font-medium text-gray-500">Submitted</label>
                <p class="text-gray-900">
                  <%= Calendar.strftime(@inquiry.inserted_at, "%m/%d/%Y %I:%M %p") %>
                </p>
              </div>
              
              <div :if={@inquiry.responded_at}>
                <label class="text-sm font-medium text-gray-500">Responded</label>
                <p class="text-gray-900">
                  <%= Calendar.strftime(@inquiry.responded_at, "%m/%d/%Y %I:%M %p") %>
                </p>
              </div>
              
              <div :if={@inquiry.updated_at != @inquiry.inserted_at}>
                <label class="text-sm font-medium text-gray-500">Last Updated</label>
                <p class="text-gray-900">
                  <%= Calendar.strftime(@inquiry.updated_at, "%m/%d/%Y %I:%M %p") %>
                </p>
              </div>
            </div>
          </div>

          <!-- Technical Information -->
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Technical Information</h2>
            <div class="space-y-3 text-sm">
              <div :if={@inquiry.ip_address}>
                <label class="font-medium text-gray-500">IP Address</label>
                <p class="text-gray-900 font-mono"><%= @inquiry.ip_address %></p>
              </div>
              
              <div :if={@inquiry.user_agent}>
                <label class="font-medium text-gray-500">User Agent</label>
                <p class="text-gray-900 break-all text-xs">
                  <%= @inquiry.user_agent %>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions
  
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

  defp status_dropdown(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <label tabindex="0" class="btn btn-sm btn-outline">
        <.status_badge status={@inquiry.status} />
        <.icon name="hero-chevron-down" class="w-4 h-4 ml-1" />
      </label>
      <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-48">
        <li :if={@inquiry.status != "pending"}>
          <button 
            phx-click="update_status" 
            phx-value-status="pending"
            class="text-warning justify-start"
          >
            <span class="badge badge-warning badge-sm">Pending</span>
            Mark as Pending
          </button>
        </li>
        <li :if={@inquiry.status != "responded"}>
          <button 
            phx-click="update_status" 
            phx-value-status="responded"
            class="text-success justify-start"
          >
            <span class="badge badge-success badge-sm">Responded</span>
            Mark as Responded
          </button>
        </li>
        <li :if={@inquiry.status != "spam"}>
          <button 
            phx-click="update_status" 
            phx-value-status="spam"
            class="text-error justify-start"
          >
            <span class="badge badge-error badge-sm">Spam</span>
            Mark as Spam
          </button>
        </li>
        <li :if={@inquiry.status != "archived"}>
          <button 
            phx-click="update_status" 
            phx-value-status="archived"
            class="text-neutral justify-start"
          >
            <span class="badge badge-ghost badge-sm">Archived</span>
            Mark as Archived
          </button>
        </li>
      </ul>
    </div>
    """
  end
end