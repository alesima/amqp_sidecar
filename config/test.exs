# config/test.exs
import Config

config :amqp,
  connections: [
    default: [
      url: "amqp://guest:guest@localhost:5672/"
    ]
  ]

config :amqp_sidecar,
  start_server: false,
  broker: AmqpSidecar.Broker.Mock,
  http_client: AmqpSidecar.Http.Mock,
  publisher: AmqpSidecar.Publisher.Mock
