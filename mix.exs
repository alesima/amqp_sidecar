defmodule AmqpSidecar.MixProject do
  use Mix.Project

  def project do
    [
      app: :amqp_sidecar,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :prometheus_ex],
      mod: {AmqpSidecar.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 3.1.0"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_plugs, "~> 1.1"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
