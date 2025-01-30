# config/config.exs

import Config

config :amqp,
  connections: [
    default: [
      host: System.get_env("RABBITMQ_HOST") || "localhost",
      port: System.get_env("RABBITMQ_PORT") || 5672,
      username: System.get_env("RABBITMQ_USERNAME") || "guest",
      password: System.get_env("RABBITMQ_PASSWORD") || "guest",
      virtual_host: System.get_env("RABBITMQ_VHOST") || "/"
    ]
  ]

config :amqp_sidecar,
  config_path: "config/broker.json"
