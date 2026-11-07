defmodule AmqpSidecar.Publisher do
  @moduledoc """
  Publishes messages to an AMQP exchange with a given routing key.

  Opens a connection per call (simple and safe for low-volume sidecar use)
  and returns `:ok` or `{:error, reason}` instead of raising.
  """

  @behaviour AmqpSidecar.PublisherBehaviour

  def publish(exchange, routing_key, message, headers \\ %{}) do
    broker = broker()

    with {:ok, conn} <- broker.open_connection(connection_url()),
         {:ok, chan} <- broker.open_channel(conn),
         :ok <-
           broker.publish(chan, exchange, routing_key, message,
             headers: normalize_headers(headers)
           ) do
      broker.close_channel(chan)
      broker.close_connection(conn)
      AmqpSidecar.Metrics.increment_messages_published(exchange)
      :ok
    else
      {:error, _} = err -> err
    end
  end

  defp normalize_headers(headers) when is_map(headers), do: Map.to_list(headers)
  defp normalize_headers(headers) when is_list(headers), do: headers
  defp normalize_headers(_), do: []

  defp broker do
    Application.get_env(:amqp_sidecar, :broker, AmqpSidecar.Broker.AMQP)
  end

  defp connection_url do
    Application.get_env(:amqp, :connections)[:default][:url]
  end
end
