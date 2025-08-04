defmodule BlindShopWeb.OrderLive.InvoicePaid do
  use BlindShopWeb, :live_view

  alias BlindShop.Payments.InvoiceService

  @impl true
  def mount(%{"session_id" => session_id}, _session, socket) do
    scope = socket.assigns.current_scope

    case handle_invoice_payment(session_id, scope) do
      {:ok, order} ->
        {:ok,
         socket
         |> assign(:page_title, "Payment Successful")
         |> assign(:order, order)
         |> assign(:success, true)
         |> assign(:error, nil)}

      {:error, reason} ->
        {:ok,
         socket
         |> assign(:page_title, "Payment Error")
         |> assign(:order, nil)
         |> assign(:success, false)
         |> assign(:error, reason)}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Payment Error")
     |> assign(:order, nil)
     |> assign(:success, false)
     |> assign(:error, "Missing payment session information")}
  end

  defp handle_invoice_payment(session_id, scope) do
    with {:ok, order} <- InvoiceService.handle_invoice_payment(session_id),
         # Verify the order belongs to the current user
         true <- order.user_id == scope.user.id do
      {:ok, order}
    else
      false -> {:error, "Order does not belong to current user"}
      error -> error
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6">
      <%= if @success do %>
        <div class="bg-success/10 border border-success rounded-lg p-8 mb-6">
          <div class="flex items-center justify-center mb-4">
            <svg class="w-16 h-16 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              >
              </path>
            </svg>
          </div>

          <h1 class="text-3xl font-bold text-center mb-4">Payment Successful!</h1>
          <p class="text-center text-lg mb-6">
            Thank you for your payment. Your order #{String.pad_leading(to_string(@order.id), 6, "0")} is now paid.
          </p>

          <div class="bg-base-200 rounded-lg p-6 mb-6">
            <h2 class="text-xl font-semibold mb-4">What Happens Next?</h2>

            <%= if @order.is_returnable do %>
              <ul class="space-y-3">
                <li class="flex items-start">
                  <span class="text-success mr-2">✓</span>
                  <div>
                    <strong>Shipping Preparation:</strong>
                    We'll carefully package your repaired blinds for safe shipping.
                  </div>
                </li>
                <li class="flex items-start">
                  <span class="text-success mr-2">✓</span>
                  <div>
                    <strong>Tracking Information:</strong>
                    You'll receive an email with tracking details once shipped.
                  </div>
                </li>
                <li class="flex items-start">
                  <span class="text-success mr-2">✓</span>
                  <div>
                    <strong>Delivery:</strong> Your blinds should arrive within 3-5 business days.
                  </div>
                </li>
              </ul>
            <% else %>
              <div class="space-y-3">
                <p>
                  As discussed, your blinds were too damaged to return safely and have been disposed of responsibly.
                </p>
                <%= if @order.disposal_reason do %>
                  <div class="bg-base-300 p-4 rounded">
                    <strong>Disposal Reason:</strong> {@order.disposal_reason}
                  </div>
                <% end %>
                <p class="text-sm text-base-content/70">
                  Thank you for choosing our repair service. If you need new blinds or have any questions,
                  please don't hesitate to contact us.
                </p>
              </div>
            <% end %>
          </div>

          <div class="text-center space-y-4">
            <.link navigate={~p"/orders/#{@order}"} class="btn btn-primary">
              View Order Details
            </.link>
            <br />
            <.link navigate={~p"/dashboard"} class="text-primary hover:underline">
              Back to Dashboard
            </.link>
          </div>
        </div>
      <% else %>
        <div class="bg-error/10 border border-error rounded-lg p-8">
          <div class="flex items-center justify-center mb-4">
            <svg class="w-16 h-16 text-error" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              >
              </path>
            </svg>
          </div>

          <h1 class="text-3xl font-bold text-center mb-4">Payment Error</h1>
          <p class="text-center text-lg mb-6">
            There was an issue processing your payment confirmation.
          </p>

          <%= if @error do %>
            <div class="bg-base-200 rounded p-4 mb-6">
              <strong>Error:</strong> {@error}
            </div>
          <% end %>

          <div class="text-center space-y-4">
            <.link navigate={~p"/orders"} class="btn btn-primary">
              View My Orders
            </.link>
            <br />
            <.link navigate={~p"/dashboard"} class="text-primary hover:underline">
              Back to Dashboard
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
