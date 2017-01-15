defmodule Ueberauth.Strategy.Foursquare do

  @moduledoc """
  Foursquare Strategy for Überauth.
  """
  use Ueberauth.Strategy, uid_field: :id,
                          oauth2_module: Ueberauth.Strategy.Foursquare.OAuth

  alias Ueberauth.Auth.Info

  def handle_request!(conn) do
    opts = [
      redirect_uri: callback_url(conn)
    ]
    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code], [redirect_uri: callback_url(conn)]])
    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  def handle_cleanup!(conn) do
    conn
    |> put_private(:foursquare_user, nil)
    |> put_private(:foursquare_token, nil)
  end

  def info(conn) do
    user = conn.private.foursquare_user

    %Info{
      name:        "#{user["firstName"]} #{user["lastName"]}",
      first_name:  user["firstName"],
      last_name:   user["lastName"],
      email:       (user["contact"] || {})["email"],
      phone:       (user["contact"] || {})["phone"],
      image:       user["photo"],
      location:    user["homeCity"],
      description: user["bio"]
    }
  end

  defp option(conn, key) do
    default_value = default_options() |> Keyword.get(key)
    options(conn) |> Keyword.get(key, default_value)
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :foursquare_token, token)
    path = "https://api.foursquare.com/v2/users/self?oauth_token=#{token.access_token}&v=20170115"
    module = option(conn, :oauth2_module)
    resp = apply(module, :get, [token, path])
    case resp do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: body}}
        when status_code in 200..399 ->
          put_private(conn, :foursquare_user, body["response"]["user"])
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

end
