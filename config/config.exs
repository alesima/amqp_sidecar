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

config :amqp_sidecar,
  config_path: "config/broker.json"
