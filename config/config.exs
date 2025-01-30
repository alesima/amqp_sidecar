# config/config.exs
import Config

config :amqp,
  connections: [
    default: [
      url: "amqp://guest:guest@localhost:5672/"
    ]
  ]

config :amqp_sidecar,
  config_path: "config/broker.json"
