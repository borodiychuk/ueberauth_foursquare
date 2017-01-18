defmodule UeberauthFoursquare.Mixfile do
  use Mix.Project

  @version    "0.1.2"
  @github_url "https://github.com/borodiychuk/ueberauth_foursquare"

  def project do
    [
      app:             :ueberauth_foursquare,
      version:         @version,
      elixir:          "~> 1.3",
      build_embedded:  Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps:            deps(),
      source_url:      @github_url,
      homepage_url:    @github_url,
      description:     description(),
      docs:            docs(),
      package:         package
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:oauth2,    "~> 0.8"},
      {:ueberauth, "~> 0.4"},
      {:credo,     "~> 0.5",   only: [:dev, :test]},
      {:earmark,   "~> 0.2",   only: :dev},
      {:ex_doc,    ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md"]]
  end

  defp description do
    "An Überauth strategy for using Foursquare to authenticate users"
  end

  defp package do
    [
      files:        ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers:  ["Andriy Borodiychuk"],
      licenses:     ["MIT"],
      links:        %{"GitHub": @github_url}
    ]
  end
end
