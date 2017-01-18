defmodule Ueberauth.Strategy.Foursquare do

  @moduledoc """
  Foursquare Strategy for Überauth.

  ### Setup

  Create an application in Foursquare for you to use.

  Register a new application at: [foursquare developer page](https://developer.foursquare.com/) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          foursquare: { Ueberauth.Strategy.Foursquare, [] }
        ]

  Then include the configuration for Foursquare.

      config :ueberauth, Ueberauth.Strategy.Foursquare.OAuth,
        client_id:     System.get_env("FOURSQUARE_CLIENT_ID"),
        client_secret: System.get_env("FOURSQUARE_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end


  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end
  """
  use Ueberauth.Strategy, uid_field: :id,
                          oauth2_module: Ueberauth.Strategy.Foursquare.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the Foursquare authentication page
  """
  def handle_request!(conn) do
    opts = [
      redirect_uri: callback_url(conn)
    ]
    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Foursquare. When there is a failure from Foursquare the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Foursquare is returned in the `Ueberauth.Auth` struct
  """
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

  @doc """
  Cleans up the private area of the connection used for passing the raw Foursquare response around during the callback
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:foursquare_user, nil)
    |> put_private(:foursquare_token, nil)
  end

  @doc """
  Includes the credentials from Foursquare response
  """
  def credentials(conn) do
    token        = conn.private.foursquare_token

    %Credentials{
      token:         token.access_token,
      refresh_token: token.refresh_token,
      expires_at:    token.expires_at,
      token_type:    token.token_type,
      expires:       !!token.expires_at,
      scopes:        []
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct
  """
  def info(conn) do
    user = conn.private.foursquare_user
    %Info{
      name:        "#{user["firstName"]} #{user["lastName"]}",
      first_name:  user["firstName"],
      last_name:   user["lastName"],
      email:       (user["contact"] || %{})["email"],
      phone:       (user["contact"] || %{})["phone"],
      image:       user["photo"],
      location:    user["homeCity"],
      description: user["bio"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Foursquare
  """
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.foursquare_token,
        user:  conn.private.foursquare_user
      }
    }
  end

  @doc """
  Fetches the uid field from the response
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.foursquare_user[uid_field]
  end


  defp option(conn, key) do
    default_value = default_options() |> Keyword.get(key)
    options(conn) |> Keyword.get(key, default_value)
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :foursquare_token, token)
    response = OAuth2.Client.get(
      OAuth2.Client.new([]),
      "https://api.foursquare.com/v2/users/self",
      [],
      params: %{v: 20170115, oauth_token: token.access_token}
    )
    case response do
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
