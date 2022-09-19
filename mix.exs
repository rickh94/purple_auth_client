defmodule PurpleAuthClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :purple_auth_client,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      applications: applications(Mix.env)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.7.0"},
      {:joken, "~> 2.5"},
      {:jason, "~> 1.3"},
      {:ex_doc, "~> 0.28.5", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
