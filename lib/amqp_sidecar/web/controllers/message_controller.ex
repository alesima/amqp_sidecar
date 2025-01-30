# lib/amqp_sidecar/web/controllers/message_controller.ex
defmodule AmqpSidecar.Web.Controllers.MessageController do
  @moduledoc """
  Handles the message publishing endpoint
  """

  use Plug.Router
  alias AmqpSidecar.Publisher

  plug(:match)
  plug(:dispatch)

  def publish(conn) do
    case read_body(conn) do
      {:ok, body, conn} ->
        case Jason.decode(body) do
          {:ok,
           %{"exchange" => exchange, "routingKey" => routing_key, "message" => message} = payload} ->
            headers = Map.get(payload, "headers", %{})
            Publisher.publish(exchange, routing_key, message, headers)
            send_resp(conn, 200, "Message published")

          {:error, reason} ->
            send_resp(conn, 400, "Invalid JSON payload")
        end

      {:error, _} ->
        send_resp(conn, 400, "Failed to read request body")
    end
  end
end
