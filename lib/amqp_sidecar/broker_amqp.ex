defmodule AmqpSidecar.Broker.AMQP do
  @moduledoc """
  `AmqpSidecar.Broker` implementation backed by the `amqp` client.
  """

  @behaviour AmqpSidecar.Broker

  alias AMQP.{Basic, Channel, Connection, Exchange, Queue}

  @impl true
  def open_connection(url) do
    Connection.open(url)
  end

  @impl true
  def open_channel(conn) do
    Channel.open(conn)
  end

  @impl true
  def declare_exchange(chan, name, "topic", opts) do
    with {:ok, _} <- Exchange.topic(chan, name, opts), do: :ok
  end

  def declare_exchange(chan, name, "direct", opts) do
    with {:ok, _} <- Exchange.direct(chan, name, opts), do: :ok
  end

  def declare_exchange(chan, name, "fanout", opts) do
    with {:ok, _} <- Exchange.fanout(chan, name, opts), do: :ok
  end

  def declare_exchange(chan, name, "x-delayed-message", opts) do
    delayed_type = Keyword.get(opts, :delayed_type) || {:error, :missing_delayed_type}

    case delayed_type do
      {:error, _} = err ->
        err

      type ->
        args = [{"x-delayed-type", :longstr, type}]

        case Exchange.declare(chan, name, :"x-delayed-message", durable: true, arguments: args) do
          {:ok, _} -> :ok
          {:error, _} = err -> err
        end
    end
  end

  def declare_exchange(_chan, _name, type, _opts) do
    {:error, {:unsupported_exchange_type, type}}
  end

  @impl true
  def declare_queue(chan, name, opts) do
    Queue.declare(chan, name, opts)
  end

  @impl true
  def bind_queue(chan, queue, exchange, opts) do
    with {:ok, _} <- Queue.bind(chan, queue, exchange, opts), do: :ok
  end

  @impl true
  def consume(chan, queue) do
    Basic.consume(chan, queue)
  end

  @impl true
  def publish(chan, exchange, routing_key, payload, opts) do
    Basic.publish(chan, exchange, routing_key, payload, opts)
  rescue
    reason -> {:error, reason}
  end

  @impl true
  def ack(chan, delivery_tag) do
    with {:ok, _} <- Basic.ack(chan, delivery_tag), do: :ok
  end

  @impl true
  def reject(chan, delivery_tag, opts) do
    with {:ok, _} <- Basic.reject(chan, delivery_tag, opts), do: :ok
  end

  @impl true
  def close_channel(chan) do
    with :ok <- Channel.close(chan), do: :ok
  end

  @impl true
  def close_connection(conn) do
    with :ok <- Connection.close(conn), do: :ok
  end
end
