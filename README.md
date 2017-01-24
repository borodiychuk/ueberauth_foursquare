# Überauth Foursquare

Foursquare OAuth2 strategy for Überauth.

[![Build Status](https://travis-ci.org/borodiychuk/ueberauth_foursquare.svg?branch=master)](https://travis-ci.org/borodiychuk/ueberauth_foursquare) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/borodiychuk/ueberauth_foursquare.svg)](https://beta.hexfaktor.org/github/borodiychuk/ueberauth_foursquare)


## Installation

1. Setup your application at [Foursquare Developer](https://developer.foursquare.com/).

1. Add `:ueberauth_foursquare` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_foursquare, "~> 0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_foursquare]]
    end
    ```

1. Add Foursquare to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        foursquare: {Ueberauth.Strategy.Foursquare, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Foursquare.OAuth,
      client_id:     System.get_env("FOURSQUARE_CLIENT_ID"),
      client_secret: System.get_env("FOURSQUARE_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

You can initial the request through:

    /auth/foursquare

## License

Please see [LICENSE](https://github.com/borodiychuk/ueberauth_foursquare/blob/master/LICENSE) for licensing details.
