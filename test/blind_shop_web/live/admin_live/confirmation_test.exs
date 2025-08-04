defmodule BlindShopWeb.AdminLive.ConfirmationTest do
  use BlindShopWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BlindShop.AdminsFixtures

  alias BlindShop.Admins

  setup do
    %{unconfirmed_admin: unconfirmed_admin_fixture(), confirmed_admin: admin_fixture()}
  end

  describe "Confirm admin" do
    test "renders confirmation page for unconfirmed admin", %{conn: conn, unconfirmed_admin: admin} do
      token =
        extract_admin_token(fn url ->
          Admins.deliver_login_instructions(admin, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/admins/log-in/#{token}")
      assert html =~ "Confirm and stay logged in"
    end

    test "renders login page for confirmed admin", %{conn: conn, confirmed_admin: admin} do
      token =
        extract_admin_token(fn url ->
          Admins.deliver_login_instructions(admin, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/admins/log-in/#{token}")
      refute html =~ "Confirm my account"
      assert html =~ "Log in"
    end

    test "confirms the given token once", %{conn: conn, unconfirmed_admin: admin} do
      token =
        extract_admin_token(fn url ->
          Admins.deliver_login_instructions(admin, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/admins/log-in/#{token}")

      form = form(lv, "#confirmation_form", %{"admin" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Admin confirmed successfully"

      assert Admins.get_admin!(admin.id).confirmed_at
      # we are logged in now
      assert get_session(conn, :admin_token)
      assert redirected_to(conn) == ~p"/"

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/admins/log-in/#{token}")
        |> follow_redirect(conn, ~p"/admins/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "logs confirmed admin in without changing confirmed_at", %{
      conn: conn,
      confirmed_admin: admin
    } do
      token =
        extract_admin_token(fn url ->
          Admins.deliver_login_instructions(admin, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/admins/log-in/#{token}")

      form = form(lv, "#login_form", %{"admin" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Welcome back!"

      assert Admins.get_admin!(admin.id).confirmed_at == admin.confirmed_at

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/admins/log-in/#{token}")
        |> follow_redirect(conn, ~p"/admins/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "raises error for invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/admins/log-in/invalid-token")
        |> follow_redirect(conn, ~p"/admins/log-in")

      assert html =~ "Magic link is invalid or it has expired"
    end
  end
end
