defmodule BlindShop.Emails.ContactEmail do
  import Swoosh.Email
  
  def contact_notification(contact) do
    new()
    |> to({"BlindShop Support", "support@blindrestoration.com"})
    |> from({"BlindShop Contact Form", "noreply@blindrestoration.com"})
    |> reply_to({contact.name, contact.email})
    |> subject("New Contact Form Submission: #{contact.subject}")
    |> html_body(contact_html(contact))
    |> text_body(contact_text(contact))
  end
  
  def contact_confirmation(contact) do
    new()
    |> to({contact.name, contact.email})
    |> from({"BlindShop Support", "support@blindrestoration.com"})
    |> subject("We've received your message")
    |> html_body(confirmation_html(contact))
    |> text_body(confirmation_text(contact))
  end
  
  defp contact_html(contact) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #4a90e2; color: white; padding: 20px; border-radius: 5px 5px 0 0; }
          .content { background-color: #f9f9f9; padding: 20px; border: 1px solid #ddd; border-top: none; }
          .field { margin-bottom: 15px; }
          .label { font-weight: bold; color: #555; }
          .value { margin-top: 5px; padding: 10px; background: white; border-radius: 3px; }
          .footer { margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>New Contact Form Submission</h2>
          </div>
          <div class="content">
            <div class="field">
              <div class="label">Name:</div>
              <div class="value">#{html_escape(contact.name)}</div>
            </div>
            
            <div class="field">
              <div class="label">Email:</div>
              <div class="value">
                <a href="mailto:#{contact.email}">#{html_escape(contact.email)}</a>
              </div>
            </div>
            
            #{if contact.phone && contact.phone != "" do
              """
              <div class="field">
                <div class="label">Phone:</div>
                <div class="value">#{html_escape(contact.phone)}</div>
              </div>
              """
            else
              ""
            end}
            
            <div class="field">
              <div class="label">Subject:</div>
              <div class="value">#{format_subject(contact.subject)}</div>
            </div>
            
            <div class="field">
              <div class="label">Message:</div>
              <div class="value" style="white-space: pre-wrap;">#{html_escape(contact.message)}</div>
            </div>
            
            <div class="footer">
              <p>This message was sent from the contact form at blindrestoration.com</p>
              <p>You can reply directly to this email to respond to the customer.</p>
            </div>
          </div>
        </div>
      </body>
    </html>
    """
  end
  
  defp contact_text(contact) do
    """
    New Contact Form Submission
    ============================
    
    Name: #{contact.name}
    Email: #{contact.email}
    #{if contact.phone && contact.phone != "", do: "Phone: #{contact.phone}\n", else: ""}Subject: #{format_subject(contact.subject)}
    
    Message:
    ------------------------
    #{contact.message}
    ------------------------
    
    This message was sent from the contact form at blindrestoration.com
    You can reply directly to this email to respond to the customer.
    """
  end
  
  defp confirmation_html(contact) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #4a90e2; color: white; padding: 20px; border-radius: 5px 5px 0 0; text-align: center; }
          .content { background-color: #f9f9f9; padding: 30px; border: 1px solid #ddd; border-top: none; }
          .message-box { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }
          .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>Thank You for Contacting Us!</h2>
          </div>
          <div class="content">
            <p>Dear #{html_escape(contact.name)},</p>
            
            <p>We've received your message and appreciate you reaching out to BlindRestoration. Our team will review your inquiry and respond within 1 business day.</p>
            
            <div class="message-box">
              <h3>Your Message:</h3>
              <p><strong>Subject:</strong> #{format_subject(contact.subject)}</p>
              <p style="white-space: pre-wrap;">#{html_escape(contact.message)}</p>
            </div>
            
            <p><strong>What happens next?</strong></p>
            <ul>
              <li>Our support team will review your message</li>
              <li>We'll respond within 1 business day (Monday-Friday)</li>
              <li>For urgent matters, you can reply to this email</li>
            </ul>
            
            <div class="footer">
              <p>Best regards,<br>The BlindRestoration Team</p>
              <p>This is an automated confirmation. Please do not reply unless you have additional information to add.</p>
            </div>
          </div>
        </div>
      </body>
    </html>
    """
  end
  
  defp confirmation_text(contact) do
    """
    Thank You for Contacting Us!
    ============================
    
    Dear #{contact.name},
    
    We've received your message and appreciate you reaching out to BlindRestoration. 
    Our team will review your inquiry and respond within 1 business day.
    
    Your Message:
    -------------
    Subject: #{format_subject(contact.subject)}
    
    #{contact.message}
    
    What happens next?
    ------------------
    • Our support team will review your message
    • We'll respond within 1 business day (Monday-Friday)
    • For urgent matters, you can reply to this email
    
    Best regards,
    The BlindRestoration Team
    
    This is an automated confirmation. Please do not reply unless you have additional information to add.
    """
  end
  
  defp format_subject(subject) do
    case subject do
      "quote" -> "Quote Request"
      "order_status" -> "Order Status"
      "general" -> "General Inquiry"
      "complaint" -> "Complaint"
      "business" -> "Business Inquiry"
      "other" -> "Other"
      _ -> subject
    end
  end
  
  defp html_escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end