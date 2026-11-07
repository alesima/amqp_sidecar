defmodule AmqpSidecar.Web.Controllers.MessageController do
  @moduledoc """
  Handles the message publishing endpoint
  """

  import Plug.Conn

  @spec publish(Plug.Conn.t()) :: Plug.Conn.t()
  def publish(conn) do
    case read_body(conn) do
      {:ok, body, conn} ->
        case Jason.decode(body) do
          {:ok,
           %{"exchange" => exchange, "routingKey" => routing_key, "message" => message} = payload} ->
            headers = Map.get(payload, "headers", %{})

            case publisher().publish(exchange, routing_key, message, headers) do
              :ok -> send_resp(conn, 200, "Message published")
              {:error, _reason} -> send_resp(conn, 502, "Failed to publish message")
            end

          _ ->
            send_resp(conn, 400, "Invalid JSON payload")
        end

      _ ->
        send_resp(conn, 400, "Failed to read request body")
    end
  end

  defp publisher do
    Application.get_env(:amqp_sidecar, :publisher, AmqpSidecar.Publisher)
  end
end
