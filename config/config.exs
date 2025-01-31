# config/config.exs
import Config

config :prometheus, AmqpSidecar.PrometheusExporter,
  path: "/metrics",
  format: Prometheus.TextFormat,
  registry: :default

config :amqp,
  connections: [
    default: [
      url: "amqp://guest:guest@localhost:5672/"
    ]
  ]

if Mix.env() == :prod do
  config :amqp_sidecar,
    config_path: "config/broker.json"
else
  config :amqp_sidecar,
    config_path: nil
end
