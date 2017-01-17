defmodule Ueberauth.Strategy.Foursquare.OAuth do

  use OAuth2.Strategy

  @api_base_url  "https://api.foursquare.com/v2"

  @defaults [
    strategy:      __MODULE__,
    site:          "https://foursquare.com",
    authorize_url: "/oauth2/authenticate",
    token_url:     "/oauth2/access_token"
  ]

  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__)
    @defaults
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
    |> OAuth2.Client.new
  end

  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], opts \\ []) do
    (opts
     |> client
     |> OAuth2.Client.get_token!(params)
    ).token
  end

  def get(token, url, headers \\ [], opts \\ []) do
    OAuth2.Client.get(client, url, headers, opts)
  end


  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_param(:grant_type, "authorization_code")
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

end
