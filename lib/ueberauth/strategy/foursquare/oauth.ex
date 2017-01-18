defmodule Ueberauth.Strategy.Foursquare.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Foursquare.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.Foursquare.OAuth,
        client_id:     System.get_env("FOURSQUARE_CLIENT_ID"),
        client_secret: System.get_env("FOURSQUARE_CLIENT_SECRET")
  """

  use OAuth2.Strategy

  @api_base_url  "https://api.foursquare.com/v2"

  @defaults [
    strategy:      __MODULE__,
    site:          "https://foursquare.com",
    authorize_url: "/oauth2/authenticate",
    token_url:     "/oauth2/access_token"
  ]

  @doc """
  Constructs a client for requests to Foursquare.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.Foursquare.OAuth.client(redirect_uri: "http://localhost:4000/auth/foursquare/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.Foursquare`.

  These options are only useful for usage outside the normal callback phase of Überauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__)
    @defaults
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
    |> OAuth2.Client.new
  end

  @doc """
  Provides the authorize url for the request phase of Überauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  @doc false
  def get_token!(params \\ [], opts \\ []) do
    (opts
     |> client
     |> OAuth2.Client.get_token!(params)
    ).token
  end

  @doc false
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  @doc false
  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_param(:grant_type, "authorization_code")
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

end
