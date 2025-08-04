defmodule BlindShopWeb.PaymentController do
  use BlindShopWeb, :controller

  alias BlindShop.Payments.StripeService
  alias BlindShop.Orders

  def success(conn, %{"session_id" => session_id}) do
    case StripeService.get_checkout_session(session_id) do
      {:ok, session} ->
        case find_order_by_session(session_id) do
          nil ->
            # Order might not be created yet due to webhook delay
            render_success_pending(conn, session)
            
          order ->
            # Order exists, show success page
            render_success_with_order(conn, order, session)
        end
        
      {:error, _error} ->
        conn
        |> put_flash(:error, "Payment verification failed. Please contact support.")
        |> redirect(to: ~p"/dashboard")
    end
  end

  def success(conn, _params) do
    conn
    |> put_flash(:error, "Invalid payment session.")
    |> redirect(to: ~p"/dashboard")
  end

  def cancel(conn, _params) do
    render(conn, :cancel, layout: false)
  end

  defp find_order_by_session(checkout_session_id) do
    BlindShop.Repo.get_by(BlindShop.Orders.Order, checkout_session_id: checkout_session_id)
  end

  defp render_success_pending(conn, session) do
    render(conn, :success_pending, 
      layout: false,
      session: session,
      customer_email: session.customer_details.email
    )
  end

  defp render_success_with_order(conn, order, session) do
    render(conn, :success_with_order,
      layout: false,
      order: order,
      session: session,
      customer_email: session.customer_details.email
    )
  end
end