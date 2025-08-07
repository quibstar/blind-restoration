defmodule BlindShopWeb.Emails.OrderEmail do
  import Swoosh.Email

  alias BlindShop.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient_email, recipient_name, subject, text_body, html_body) do
    email =
      new()
      |> to({recipient_name, recipient_email})
      |> from({"BlindShop", "support@blindrestoration.com"})
      |> subject(subject)
      |> text_body(text_body)
      |> html_body(html_body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  # Render email template with layout
  defp render_template(template_name, assigns) do
    # The path to the templates directory
    templates_path = "priv/email_templates"

    # Convert assigns to atom map for proper @ access in templates
    atom_assigns = assigns_to_atom_map(assigns)

    # Add helper functions to template context
    helper_assigns =
      Map.merge(atom_assigns, %{
        estimated_completion: &estimated_completion/1,
        expected_delivery: &expected_delivery/1,
        get_tracking_url: &get_tracking_url/2
      })

    # Render the specific email template
    template_path = Path.join([templates_path, "order", "#{template_name}.html.eex"])
    inner_content = EEx.eval_file(template_path, assigns: helper_assigns)

    # Render the layout with the content
    layout_assigns = Map.put(helper_assigns, :inner_content, inner_content)
    layout_path = Path.join([templates_path, "layouts", "app.html.eex"])

    EEx.eval_file(layout_path, assigns: layout_assigns)
  end

  # Convert string keys to atom keys for proper @ access in templates
  defp assigns_to_atom_map(assigns) do
    Enum.into(assigns, %{}, fn {key, value} ->
      atom_key = if is_atom(key), do: key, else: String.to_atom(key)
      {atom_key, value}
    end)
  end

  def order_confirmation(order, user) do
    subject = "Order Confirmation - ##{String.pad_leading(to_string(order.id), 6, "0")}"

    text_body = """
    Order Confirmation

    Hi #{user.first_name},

    Thank you for your order! We're excited to repair your blinds.

    Order Details:
    - Order Number: ##{String.pad_leading(to_string(order.id), 6, "0")}
    
    Items:
    #{Enum.map_join(order.order_line_items, "\n", fn item ->
      "- #{format_blind_type(item.blind_type)} #{item.width}\" × #{item.height}\" (Qty: #{item.quantity})"
    end)}
    
    - Total Price: $#{order.total_price}

    What's Next?
    1. Package your blinds following our shipping guidelines
    2. Print the shipping label (if provided)
    3. Ship to us using any carrier
    4. We'll notify you when we receive and complete your repair

    Ship To:
    Blind Restoration
    11034 Island CT.
    Allendale, MI 49401

    Include Order ##{String.pad_leading(to_string(order.id), 6, "0")} on package

    Best regards,
    The BlindRestoration Team
    """

    html_body =
      render_template("order_confirmation", %{order: order, user: user, subject: subject})

    deliver(user.email, "#{user.first_name} #{user.last_name}", subject, text_body, html_body)
  end

  def order_processing(order, user) do
    subject =
      "We're Working on Your Blinds! - Order ##{String.pad_leading(to_string(order.id), 6, "0")}"

    text_body = """
    We're Working on Your Blinds!

    Hi #{user.first_name},

    Great news! We've received your blinds and our expert technician has started working on them.

    Current Status: Processing

    Estimated completion: #{estimated_completion(order.service_level)}

    What We're Doing:
    - Inspecting your blinds
    - Replacing damaged cords with matching material
    - Cleaning all components
    - Testing for smooth operation
    - Preparing for safe return shipping

    We'll send you another email as soon as your blinds are ready to ship back to you.

    Best regards,
    The BlindRestoration Team
    """

    html_body = render_template("order_processing", %{order: order, user: user, subject: subject})

    deliver(user.email, "#{user.first_name} #{user.last_name}", subject, text_body, html_body)
  end

  def order_shipped(order, user) do
    subject =
      "Your Blinds Have Shipped! - Order ##{String.pad_leading(to_string(order.id), 6, "0")}"

    text_body = """
    Your Blinds Are On The Way!

    Hi #{user.first_name},

    Great news! Your freshly repaired blinds have been shipped and are on their way back to you.

    #{if order.tracking_number do
      carrier_text = if order.carrier, do: "#{String.upcase(order.carrier)} ", else: ""
      "#{carrier_text}Tracking Number: #{order.tracking_number}"
      <> if order.carrier && order.tracking_number do
        "\nTrack at: #{get_tracking_url(order.carrier, order.tracking_number)}"
      else
        ""
      end
    else
      "Tracking information will be updated soon."
    end}

    Expected Delivery: #{expected_delivery(order.service_level)}

    What We Did:
    - Restrung your blinds with matching cord
    - Cleaned and inspected all components
    - Tested for smooth operation
    - Carefully packaged for safe delivery

    Thank you for choosing BlindShop!

    Best regards,
    The BlindRestoration Team

    P.S. Need another repair? Get 10% off your next order with code REPEAT10
    """

    html_body = render_template("order_shipped", %{order: order, user: user, subject: subject})

    deliver(user.email, "#{user.first_name} #{user.last_name}", subject, text_body, html_body)
  end

  def order_completed(order, user) do
    subject = "Your Order is Complete - Thank You!"

    text_body = """
    Thank You!

    Hi #{user.first_name},

    We hope you love your repaired blinds!

    Your satisfaction is our top priority. If you have any questions or concerns about your repaired blinds, please don't hesitate to reach out.

    Special Offer Just for You!
    Get 15% OFF your next repair order
    Code: REPEAT15
    Valid for 60 days

    Know someone with broken blinds? Refer them to BlindShop and you'll both get 20% off!

    Thank you for choosing BlindShop. We truly appreciate your business!

    Best regards,
    The BlindRestoration Team
    """

    html_body = render_template("order_completed", %{order: order, user: user, subject: subject})

    deliver(user.email, "#{user.first_name} #{user.last_name}", subject, text_body, html_body)
  end

  def invoice_ready(order, user, payment_url) do
    shipping_cost = order.shipping_cost || Decimal.new("0")
    total_due = if order.is_returnable && Decimal.compare(shipping_cost, Decimal.new("0")) == :gt do
      Decimal.add(order.total_price, shipping_cost)
    else
      order.total_price
    end

    subject = "Your Blinds Are Ready - Invoice ##{String.pad_leading(to_string(order.id), 6, "0")}"

    text_body = """
    Your Blinds Are Ready for Payment!

    Hi #{user.first_name},

    Great news! We've completed the repair of your blinds and they're ready for return shipping.

    Order Summary:
    - Order Number: ##{String.pad_leading(to_string(order.id), 6, "0")}
    
    Items Repaired:
    #{Enum.map_join(order.order_line_items, "\n", fn item ->
      "- #{format_blind_type(item.blind_type)} #{item.width}\" × #{item.height}\" (Qty: #{item.quantity})"
    end)}
    
    - Repair Service: $#{order.total_price}
    #{if order.is_returnable && Decimal.compare(shipping_cost, Decimal.new("0")) == :gt do
      "- Return Shipping: $#{shipping_cost}"
    else
      if !order.is_returnable do
        "- Return Shipping: N/A (blinds disposed due to damage)"
      else
        ""
      end
    end}
    
    Total Due: $#{total_due}

    #{if order.is_returnable do
      "What We Did:
      - Restrung your blinds with matching cord
      - Cleaned and inspected all components  
      - Tested for smooth operation
      - Prepared for safe return shipping"
    else
      "What We Did:
      - Assessed your blinds for repair feasibility
      - Unfortunately, the blinds were too damaged to repair safely
      - We've disposed of them responsibly as requested
      
      Disposal Reason: #{order.disposal_reason || "Excessive damage beyond repair"}"
    end}

    PAYMENT REQUIRED: Please click the link below to complete payment and #{if order.is_returnable, do: "arrange return shipping", else: "close this order"}:

    #{payment_url}

    Questions? Reply to this email or contact us at support@blindrestoration.com

    Best regards,
    The BlindRestoration Team
    """

    html_body = render_template("invoice_ready", %{
      order: order, 
      user: user, 
      subject: subject, 
      payment_url: payment_url,
      shipping_cost: shipping_cost,
      total_due: total_due
    })

    # Return email struct for OrderNotifier to deliver
    new()
    |> to({"#{user.first_name} #{user.last_name}", user.email})
    |> from({"BlindShop", "support@blindrestoration.com"})
    |> subject(subject)
    |> text_body(text_body)
    |> html_body(html_body)
  end

  def shipping_reminder(order, user) do
    subject =
      "Don't Forget to Ship Your Blinds - Order ##{String.pad_leading(to_string(order.id), 6, "0")}"

    text_body = """
    Shipping Reminder

    Hi #{user.first_name},

    We noticed you haven't shipped your blinds yet for Order ##{String.pad_leading(to_string(order.id), 6, "0")}.

    To get your blinds repaired, please ship them to:

    Blind Restoration
    11034 Island CT.
    Allendale, MI 49401

    Don't forget to include your order number on the package!

    Need help with shipping? Visit our shipping instructions page or reply to this email.

    Best regards,
    The BlindRestoration Team
    """

    html_body =
      render_template("shipping_reminder", %{order: order, user: user, subject: subject})

    deliver(user.email, "#{user.first_name} #{user.last_name}", subject, text_body, html_body)
  end

  # Helper functions
  defp estimated_completion(service_level) do
    case service_level do
      "express" -> "Within 2 days"
      "priority" -> "Within 3 days"
      "rush" -> "Within 5 days"
      _ -> "Within 7-10 days"
    end
  end

  defp expected_delivery(service_level) do
    case service_level do
      "express" -> "2-3 business days"
      "priority" -> "3-4 business days"
      "rush" -> "4-5 business days"
      _ -> "5-7 business days"
    end
  end

  defp format_blind_type(blind_type) do
    case blind_type do
      "mini" -> "Mini Blinds"
      "vertical" -> "Vertical Blinds"
      "honeycomb" -> "Honeycomb/Cellular"
      "wood" -> "Wood/Faux Wood"
      "roman" -> "Roman Shades"
      _ -> String.capitalize(blind_type || "Unknown")
    end
  end

  # Generate tracking URL for different carriers
  defp get_tracking_url(carrier, tracking_number) when is_binary(carrier) and is_binary(tracking_number) do
    case String.downcase(carrier) do
      "ups" -> "https://www.ups.com/track?track=yes&trackNums=#{tracking_number}"
      "fedex" -> "https://www.fedex.com/fedextrack/?trknbr=#{tracking_number}"
      "usps" -> "https://tools.usps.com/go/TrackConfirmAction?tLabels=#{tracking_number}"
      "dhl" -> "https://www.dhl.com/us-en/home/tracking.html?tracking-id=#{tracking_number}"
      _ -> "https://www.google.com/search?q=track+package+#{tracking_number}"
    end
  end
  defp get_tracking_url(_, _), do: ""
end
