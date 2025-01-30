# lib/amqp_sidecar/consumer.ex
defmodule AmqpSidecar.Consumer do
  @moduledoc """
  Dynamically creates AMQP consumers based on the configuration
  """

  use GenServer
  require Logger

  alias AMQP.{Queue, Exchange, Basic}

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    connection_config = Application.get_env(:amqp, :connections)[:default][:url]

    {:ok, conn} = AMQP.Connection.open(connection_config)
    {:ok, chan} = AMQP.Channel.open(conn)

    Enum.each(config["rules"], &setup_consumer(chan, &1))

    {:ok, %{conn: conn, chan: chan}}
  end

  defp setup_consumer(chan, rule) do
    exchange = rule["exchange"]
    exchange_type = rule["exchangeType"] || "topic"
    exchange_arguments = rule["exchangeArguments"] || %{}
    queue = rule["queue"]
    routing_keys = rule["routingKeys"]
    endpoint_uri = rule["endpointUri"]

    case exchange_type do
      "topic" ->
        Exchange.topic(chan, exchange, durable: true)

      "direct" ->
        Exchange.direct(chan, exchange, durable: true)

      "fanout" ->
        Exchange.fanout(chan, exchange, durable: true)

      "x-delayed-message" ->
        delayed_type =
          exchange_arguments["x-delayed-type"] || raise "x-delayed-type argument is required"

        Exchange.topic(chan, exchange,
          durable: true,
          arguments: [{"x-delayed-type", :longstr, delayed_type}]
        )
    end

    Queue.declare(chan, queue, durable: true)

    case exchange_type do
      "fanout" ->
        Queue.bind(chan, queue, exchange)

      _ ->
        Enum.each(routing_keys, &Queue.bind(chan, queue, exchange, routing_key: &1))
    end

    Basic.consume(chan, queue)

    Logger.info(
      "Subscribed to exchange #{exchange} with queue #{queue} and routing keys #{routing_keys} for endpoint #{endpoint_uri}"
    )
  end

  @impl true
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:basic_deliver, payload, meta}, state) do
    Logger.info("Received message #{payload} from #{meta.delivery_tag}")

    rule = find_rule_for_queue(meta.routing_key)
    forward_message(rule["endpointUri"], payload)

    Basic.ack(state.chan, meta.delivery_tag)

    {:noreply, state}
  end

  defp find_rule_for_queue(rounting_key) do
    config = AmqpSidecar.Config.load_config() |> AmqpSidecar.Config.validate_config()

    Enum.find(config["rules"], fn rule ->
      Enum.any?(rule["routingKeys"], &(&1 == rounting_key))
    end)
  end

  defp forward_message(endpoint_uri, payload) do
    case HTTPoison.post(endpoint_uri, payload, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("Successfully forwarded message to #{endpoint_uri}")

      {:error, reason} ->
        Logger.error("Failed to forward message to #{endpoint_uri}: #{reason}")
    end
  end
end
