# lib/amqp_sidecar/publisher.ex
defmodule AmqpSidecar.Publisher do
  @moduledoc """
  Publishes messages to an AMQP exchange with a given routing key
  """

  alias AMQP.{Connection, Channel, Exhange, Basic}

  def publish(exchange, routing_key, message, headers \\ %{}) do
    connection_config = Application.get_env(:amqp, :connections)[:default]

    {:ok, conn} = Connection.open(connection_config)
    {:ok, chan} = Channel.open(conn)

    Basic.publish(chan, exchange, routing_key, message, headers: headers)
    Channel.close(chan)
    Connection.close(conn)
  end
end
