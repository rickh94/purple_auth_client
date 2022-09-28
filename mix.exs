defmodule PurpleAuthClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :purple_auth_client,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      package: package(),
      preferred_cli_env: [
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ],
      name: "Purple Auth Client",
      docs: [
        main: "PurpleAuthClient",
        extras: ["README.md"]
      ]
    ]
  end

  defp description do
    """
    Client for my Purple Auth passwordless authentication service.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Rick Henry"],
      licenses: ["MIT"],
      links: %{"GitHub" => ""}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.7.0"},
      {:joken, "~> 2.5"},
      {:jason, "~> 1.3"},
      {:ex_doc, "~> 0.28.5", only: :dev, runtime: false},
      {:exvcr, "~> 0.13.4", only: :test}
    ]
  end
end
