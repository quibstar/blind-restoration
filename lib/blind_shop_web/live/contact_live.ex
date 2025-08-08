defmodule BlindShopWeb.ContactLive do
  use BlindShopWeb, :live_view

  alias BlindShop.Contacts.Contact
  alias BlindShop.Contacts.ContactSubmission
  alias BlindShop.Emails.ContactEmail
  alias BlindShop.Repo

  @impl true
  def mount(_params, _session, socket) do
    changeset = Contact.changeset(%Contact{}, %{})

    {:ok,
     socket
     |> assign(:page_title, "Contact Us | BlindRestoration")
     |> assign(
       :meta_description,
       "Contact BlindRestoration for blind repair quotes, order status, or general inquiries. We typically respond within 24 hours."
     )
     |> assign(:canonical_url, "https://blindrestoration.com/contact")
     |> assign(:form, to_form(changeset))
     |> assign(:submitted, false)
     |> assign(:user_agent, get_user_agent(socket))
     |> assign(:ip_address, get_ip_address(socket))}
  end

  @impl true
  def handle_event("validate", %{"contact" => contact_params}, socket) do
    changeset =
      %Contact{}
      |> Contact.changeset(contact_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("submit", %{"contact" => contact_params}, socket) do
    # Debug: Log the contact params to see what's being submitted
    require Logger
    Logger.debug("Contact params received: #{inspect(contact_params)}")
    
    changeset = Contact.changeset(%Contact{}, contact_params)
    
    # Debug: Log changeset validation state
    Logger.debug("Changeset valid: #{changeset.valid?}, errors: #{inspect(changeset.errors)}")

    case changeset do
      %{valid?: true, errors: []} ->
        # Valid submission
        contact = Ecto.Changeset.apply_changes(changeset)

        # Save to database with additional metadata
        submission_attrs = %{
          name: contact.name,
          email: contact.email,
          phone: contact.phone,
          subject: contact.subject,
          message: contact.message,
          user_agent: socket.assigns.user_agent,
          ip_address: socket.assigns.ip_address
        }

        case Repo.insert(ContactSubmission.changeset(%ContactSubmission{}, submission_attrs)) do
          {:ok, submission} ->
            # Send email notifications
            spawn(fn ->
              try do
                # Send notification to support team
                contact
                |> ContactEmail.contact_notification()
                |> BlindShop.Mailer.deliver()

                # Send confirmation to customer
                contact
                |> ContactEmail.contact_confirmation()
                |> BlindShop.Mailer.deliver()

                require Logger
                Logger.info("Contact form emails sent for submission #{submission.id}")
              rescue
                error ->
                  require Logger
                  Logger.error("Failed to send contact form emails: #{inspect(error)}")
              end
            end)

            require Logger
            Logger.info("Contact form submission saved - ID: #{submission.id}, from #{contact.name} (#{contact.email}): #{contact.subject}")

            {:noreply,
             socket
             |> put_flash(:info, "Thank you for contacting us! We'll respond within 1 business day.")
             |> assign(:submitted, true)
             |> assign(:form, to_form(Contact.changeset(%Contact{}, %{})))}

          {:error, changeset_error} ->
            require Logger
            Logger.error("Failed to save contact submission: #{inspect(changeset_error.errors)}")

            {:noreply,
             socket
             |> put_flash(:error, "There was an error submitting your message. Please try again.")
             |> assign(:form, to_form(Map.put(changeset, :action, :validate)))}
        end

      %{valid?: true} ->
        # Valid changeset but has honeypot errors - bot detected
        require Logger
        Logger.warning("Honeypot triggered - potential bot submission blocked")

        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your message. We'll get back to you soon!")
         |> assign(:submitted, true)}

      %{valid?: false} ->
        # Invalid form
        {:noreply,
         socket
         |> put_flash(:error, "Please correct the errors below.")
         |> assign(:form, to_form(Map.put(changeset, :action, :validate)))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="container mx-auto px-4 py-8">
        <div class="max-w-4xl mx-auto">
          <h1 class="text-4xl font-bold text-center mb-8 text-primary">Contact Us</h1>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <!-- Contact Form -->
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title text-2xl mb-4">Send us a Message</h2>

                <.form
                  :if={!@submitted}
                  for={@form}
                  phx-change="validate"
                  phx-submit="submit"
                  id="contact-form"
                >
                  <.input
                    field={@form[:name]}
                    type="text"
                    label="Your Name *"
                    placeholder="John Doe"
                    required
                  />

                  <.input
                    field={@form[:email]}
                    type="email"
                    label="Email Address *"
                    placeholder="john@example.com"
                    required
                  />

                  <.input
                    field={@form[:phone]}
                    type="tel"
                    label="Phone Number"
                    placeholder="(555) 123-4567"
                  />

                  <.input
                    field={@form[:subject]}
                    type="select"
                    label="Subject *"
                    prompt="Select a subject"
                    options={[
                      {"Quote Request", "quote"},
                      {"Order Status", "order_status"},
                      {"General Inquiry", "general"},
                      {"Complaint", "complaint"},
                      {"Business Inquiry", "business"},
                      {"Other", "other"}
                    ]}
                    required
                  />

                  <.input
                    field={@form[:message]}
                    type="textarea"
                    label="Message *"
                    placeholder="How can we help you?"
                    rows="5"
                    required
                  />
                  
    <!-- Honeypot Fields - Hidden from users -->
                  <div style="position: absolute; left: -5000px;" aria-hidden="true">
                    <input
                      type="text"
                      name="contact[website]"
                      value=""
                      tabindex="-1"
                      autocomplete="off"
                    />
                  </div>

                  <div class="ohnohoney">
                    <input
                      type="text"
                      name="contact[company]"
                      value=""
                      tabindex="-1"
                      autocomplete="off"
                    />
                  </div>

                  <div class="form-control mt-6">
                    <.button type="submit" phx-disable-with="Sending..." variant="primary">
                      Send Message <.icon name="hero-arrow-right" class="h-5 w-5 ml-2" />
                    </.button>
                  </div>

                  <p class="text-sm text-base-content/60 mt-4">
                    * Required fields. We typically respond within 1 business day.
                  </p>
                </.form>

                <div :if={@submitted} class="text-center py-8">
                  <.icon name="hero-check-circle" class="h-16 w-16 text-success mx-auto mb-4" />
                  <h3 class="text-xl font-semibold mb-2">Message Sent!</h3>
                  <p class="text-base-content/70 mb-6">
                    We've received your message and will respond within 1 business day.
                  </p>
                  <.button phx-click={JS.push("reset_form")} variant="primary">
                    Send Another Message
                  </.button>
                </div>
              </div>
            </div>
            
    <!-- Contact Information -->
            <div class="space-y-6">
              <!-- Quick Contact Info -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h2 class="card-title text-2xl mb-4">Get in Touch</h2>

                  <div class="space-y-4">
                    <!-- Email -->
                    <div class="flex items-start gap-3">
                      <.icon name="hero-envelope" class="h-6 w-6 text-primary mt-1" />
                      <div>
                        <p class="font-semibold">Email</p>
                        <p class="text-base-content/70">
                          Use the contact form or email<br />
                          <span class="select-all font-mono text-sm">
                            support [at] blindrestoration.com
                          </span>
                        </p>
                      </div>
                    </div>
                    
    <!-- Response Time -->
                    <div class="flex items-start gap-3">
                      <.icon name="hero-clock" class="h-6 w-6 text-primary mt-1" />
                      <div>
                        <p class="font-semibold">Response Time</p>
                        <p class="text-base-content/70">Usually within 24 hours</p>
                      </div>
                    </div>
                    
    <!-- Business Hours -->
                    <div class="flex items-start gap-3">
                      <.icon name="hero-building-office-2" class="h-6 w-6 text-primary mt-1" />
                      <div>
                        <p class="font-semibold">Business Hours</p>
                        <p class="text-base-content/70">Monday - Friday: 9:00 AM - 5:00 PM PST</p>
                        <p class="text-base-content/70">Saturday - Sunday: Closed</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- FAQ Link -->
              <div class="card bg-primary text-primary-content shadow-xl">
                <div class="card-body">
                  <h3 class="card-title text-xl">Common Questions?</h3>
                  <p>
                    Check out our FAQ section for quick answers to common questions about our blind repair services.
                  </p>
                  <div class="card-actions justify-end mt-4">
                    <.link navigate={~p"/faq"} class="btn btn-primary-content btn-sm">
                      View FAQ <.icon name="hero-arrow-right" class="h-4 w-4 ml-1" />
                    </.link>
                  </div>
                </div>
              </div>
              
    <!-- Special Requests -->
              <div class="alert alert-info">
                <.icon name="hero-information-circle" class="h-6 w-6" />
                <div>
                  <h4 class="font-bold">Business Accounts</h4>
                  <p class="text-sm">
                    Property managers and businesses, contact us for special pricing and terms.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("reset_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, to_form(Contact.changeset(%Contact{}, %{})))
     |> assign(:submitted, false)
     |> clear_flash()}
  end

  # Helper functions for extracting request metadata
  defp get_user_agent(socket) do
    case get_connect_info(socket, :user_agent) do
      nil -> nil
      user_agent -> user_agent |> String.slice(0, 255)  # Truncate to fit database
    end
  end

  defp get_ip_address(socket) do
    case get_connect_info(socket, :peer_data) do
      %{address: ip} -> ip |> :inet.ntoa() |> to_string()
      _ -> nil
    end
  end
end
