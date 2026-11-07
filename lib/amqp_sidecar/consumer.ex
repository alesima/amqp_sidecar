defmodule AmqpSidecar.Consumer do
  @moduledoc """
  Dynamically creates AMQP consumers based on the configuration.

  Rules are matched by exchange plus AMQP topic patterns (`*` matches one
  word, `#` matches zero or more words). Messages that match no rule are
  acknowledged and dropped with a warning so they don't poison the queue.
  A failed forward rejects the message with requeue so RabbitMQ redelivers it.
  """

  use GenServer
  require Logger

  defstruct [:conn, :chan, rules: []]

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    rules = normalize_rules(config["rules"] || config[:rules] || [])

    with {:ok, conn} <- broker().open_connection(connection_url()),
         {:ok, chan} <- broker().open_channel(conn),
         :ok <- setup_all(chan, rules) do
      AmqpSidecar.Metrics.update_connections(connection_host(), 1)
      {:ok, %__MODULE__{conn: conn, chan: chan, rules: rules}}
    else
      {:error, reason} -> {:stop, reason}
    end
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
    case match_rule(state.rules, meta.exchange, meta.routing_key) do
      nil ->
        Logger.warning("No rule for #{meta.exchange}:#{meta.routing_key}, dropping message")
        broker().ack(state.chan, meta.delivery_tag)

      rule ->
        deliver(rule, payload, meta, state)
    end

    {:noreply, state}
  end

  @doc """
  Matches a rule by exchange and topic routing key.
  `*` matches exactly one word, `#` matches zero or more words.
  """
  @spec match_rule([map()], String.t(), String.t()) :: map() | nil
  def match_rule(rules, exchange, routing_key) do
    Enum.find(rules, fn rule ->
      rule.exchange == exchange and
        Enum.any?(rule.patterns, &topic_match?(&1, routing_key))
    end)
  end

  @doc """
  AMQP topic pattern matching.
  """
  @spec topic_match?(String.t(), String.t()) :: boolean()
  def topic_match?("#", _key), do: true

  def topic_match?(pattern, key) do
    do_match?(String.split(pattern, "."), String.split(key, "."))
  end

  defp do_match?(["#" | _], _), do: true
  defp do_match?([], []), do: true
  defp do_match?([], _), do: false
  defp do_match?(_, []), do: false
  defp do_match?(["*" | rest_p], [_ | rest_k]), do: do_match?(rest_p, rest_k)
  defp do_match?([p | rest_p], [p | rest_k]), do: do_match?(rest_p, rest_k)
  defp do_match?(_, _), do: false

  defp deliver(rule, payload, meta, state) do
    Logger.info("Received message for #{rule.queue} from #{meta.delivery_tag}")
    AmqpSidecar.Metrics.increment_messages_delivered(rule.queue)

    case http_client().post(rule.endpoint, payload, [{"Content-Type", "application/json"}]) do
      {:ok, %{status_code: code}} when code in 200..299 ->
        Logger.info("Forwarded message to #{rule.endpoint}")
        broker().ack(state.chan, meta.delivery_tag)

      {:ok, %{status_code: code}} ->
        Logger.error("Endpoint #{rule.endpoint} returned #{code}, requeueing")
        broker().reject(state.chan, meta.delivery_tag, requeue: true)

      {:error, reason} ->
        Logger.error(
          "Failed to forward message to #{rule.endpoint}: #{inspect(reason)}, requeueing"
        )

        broker().reject(state.chan, meta.delivery_tag, requeue: true)
    end
  end

  defp normalize_rules(rules) do
    Enum.map(rules, fn rule ->
      %{
        exchange: rule["exchange"] || rule[:exchange],
        exchange_type: rule["exchangeType"] || rule[:exchangeType] || "topic",
        exchange_arguments: rule["exchangeArguments"] || rule[:exchangeArguments] || %{},
        queue: rule["queue"] || rule[:queue],
        patterns: rule["routingKeys"] || rule[:routingKeys] || [],
        endpoint: rule["endpointUri"] || rule[:endpointUri]
      }
    end)
  end

  defp setup_all(chan, rules) do
    Enum.reduce_while(rules, :ok, fn rule, :ok ->
      case setup_consumer(chan, rule) do
        :ok -> {:cont, :ok}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp setup_consumer(chan, rule) do
    broker = broker()

    with :ok <-
           broker.declare_exchange(chan, rule.exchange, rule.exchange_type, exchange_opts(rule)),
         {:ok, _} <- broker.declare_queue(chan, rule.queue, durable: true),
         :ok <- bind_all(chan, rule),
         {:ok, _tag} <- broker.consume(chan, rule.queue) do
      Logger.info("Subscribed to #{rule.exchange}:#{rule.queue} -> #{rule.endpoint}")
      :ok
    end
  end

  defp exchange_opts(%{exchange_type: "x-delayed-message", exchange_arguments: args}) do
    [delayed_type: args["x-delayed-type"] || args[:x_delayed_type]]
  end

  defp exchange_opts(_), do: [durable: true]

  defp bind_all(chan, %{exchange_type: "fanout"} = rule) do
    broker().bind_queue(chan, rule.queue, rule.exchange, [])
  end

  defp bind_all(chan, rule) do
    Enum.reduce_while(rule.patterns, :ok, fn pattern, :ok ->
      case broker().bind_queue(chan, rule.queue, rule.exchange, routing_key: pattern) do
        :ok -> {:cont, :ok}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp broker do
    Application.get_env(:amqp_sidecar, :broker, AmqpSidecar.Broker.AMQP)
  end

  defp http_client do
    Application.get_env(:amqp_sidecar, :http_client, AmqpSidecar.Http.HTTPoison)
  end

  defp connection_url do
    Application.get_env(:amqp, :connections)[:default][:url]
  end

  defp connection_host do
    case URI.parse(connection_url() || "") do
      %URI{host: nil} -> "unknown"
      %URI{host: host} -> host
    end
  end
end
