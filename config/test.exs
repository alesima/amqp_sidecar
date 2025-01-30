# config/test.exs
config :amqp,
  connections: [
    default: [
      url: "amqp://guest:guest@localhost:5672/"
    ]
  ]
