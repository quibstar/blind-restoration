defmodule BlindShopWeb.PaymentHTML do
  @moduledoc """
  This module contains pages rendered by PaymentController.
  """
  use BlindShopWeb, :html

  embed_templates "payment_html/*"
end