# lib/amqp_sidecar/application.ex
defmodule AmqpSidecar.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    config = AmqpSidecar.Config.load_config() |> AmqpSidecar.Config.validate_config()

    children = [
      {AmqpSidecar.Consumer, config},
      {Plug.Cowboy, scheme: :http, plug: AmqpSidecar.Web.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: AmqpSidecar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
