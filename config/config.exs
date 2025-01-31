# config/config.exs
import Config

config :prometheus, AmqpSidecar.PrometheusExporter,
  path: "/metrics",
  format: Prometheus.TextFormat,
  registry: :default

config :prometheus,
  metrics: [
    Counter.declare(
      name: :http_requests_total,
      help: "HTTP request count",
      labels: [:method, :status]
    )
  ]

config :amqp,
  connections: [
    default: [
      url: "amqp://guest:guest@localhost:5672/"
    ]
  ]

config :amqp_sidecar,
  config_path: "config/broker.json"
