defmodule BlindShopWeb.PageController do
  use BlindShopWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> assign(:page_title, "Professional Blind Repair Service | 10-Day Turnaround")
    |> assign(:meta_description, "Expert blind repair service with guaranteed 10-day turnaround. Mail-in blind restringing for mini, vertical, honeycomb, and roman blinds. Get instant quote online.")
    |> assign(:meta_keywords, "blind repair, blind restringing, blind repair service, mini blind repair, vertical blind repair, mail-in blind repair, 10-day turnaround")
    |> assign(:canonical_url, "https://blindrestoration.com")
    |> render(:home, layout: false)
  end

  def shipping_instructions(conn, _params) do
    conn
    |> assign(:page_title, "How to Ship Blinds for Repair | Free Shipping Guide")
    |> assign(:meta_description, "Complete guide on how to safely ship your blinds for professional repair. Free shipping instructions, packing tips, and shipping address included.")
    |> assign(:meta_keywords, "ship blinds for repair, blind shipping instructions, how to ship blinds, blind repair shipping, mail-in blind repair")
    |> assign(:canonical_url, "https://blindrestoration.com/shipping-instructions")
    |> render(:shipping_instructions, layout: false)
  end

  def terms_of_service(conn, _params) do
    conn
    |> assign(:page_title, "Terms of Service | BlindRestoration")
    |> assign(:meta_description, "Terms of Service for BlindRestoration blind repair service. Review our policies for mail-in blind repair and restoration services.")
    |> assign(:canonical_url, "https://blindrestoration.com/terms-of-service")
    |> render(:terms_of_service)
  end

  def privacy_policy(conn, _params) do
    conn
    |> assign(:page_title, "Privacy Policy | BlindRestoration")
    |> assign(:meta_description, "Privacy Policy for BlindRestoration. Learn how we protect your personal information when using our blind repair services.")
    |> assign(:canonical_url, "https://blindrestoration.com/privacy-policy")
    |> render(:privacy_policy)
  end
end
