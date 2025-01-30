# config/runtime.exs
import Config

config :amqp,
  connections: [
    default: [
      url: System.get_env("AMQP_URL", "amqp://guest:guest@localhost:5672/")
    ]
  ]
