# lib/amqp_sidecar/application.ex
defmodule AmqpSidecar.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    config = AmqpSidecar.Config.load_config() |> AmqpSidecar.Config.validate_config()

    children = [
      {AmqpSidecar.Consumer, config},
      {Plug.Cowboy, scheme: :http, plug: AmqpSidecar.Web.Router, options: [port: 4000, ip: {0, 0, 0, 0}]},
      {AmqpSidecar.Metrics, []}
    ]

    opts = [strategy: :one_for_one, name: AmqpSidecar.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("Running AMQP Sidecar on port 4000")
        {:ok, pid}

      {:error, reason} ->
        Logger.error("Failed to start AMQP Sidecar: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
