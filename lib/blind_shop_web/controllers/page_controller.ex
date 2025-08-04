defmodule BlindShopWeb.PageController do
  use BlindShopWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def shipping_instructions(conn, _params) do
    render(conn, :shipping_instructions, layout: false)
  end

  def terms_of_service(conn, _params) do
    render(conn, :terms_of_service)
  end

  def privacy_policy(conn, _params) do
    render(conn, :privacy_policy)
  end
end
