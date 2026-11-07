defmodule AmqpSidecar.Web.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Mox

  alias AmqpSidecar.Publisher.Mock, as: PublisherMock
  alias AmqpSidecar.Web.Router

  @opts Router.init([])

  setup :verify_on_exit!

  setup do
    AmqpSidecar.Metrics.setup()
    :ok
  end

  describe "GET /health" do
    test "returns 200 OK" do
      conn = conn(:get, "/health") |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body == "OK"
    end
  end

  describe "POST /publish" do
    test "publishes a message to an AMQP exchange" do
      expect(PublisherMock, :publish, fn "test_exchange", "test_key", "test_message", %{} ->
        :ok
      end)

      conn =
        conn(
          :post,
          "/publish",
          ~s({"exchange": "test_exchange", "routingKey": "test_key", "message": "test_message"})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body == "Message published"
    end

    test "returns 502 when publishing fails" do
      expect(PublisherMock, :publish, fn _, _, _, _ -> {:error, :econnrefused} end)

      conn =
        conn(
          :post,
          "/publish",
          ~s({"exchange": "test_exchange", "routingKey": "test_key", "message": "test_message"})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 502
      assert conn.resp_body == "Failed to publish message"
    end

    test "returns 400 for invalid JSON payload" do
      conn =
        conn(:post, "/publish", "invalid_json")
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 400
      assert conn.resp_body == "Invalid JSON payload"
    end

    test "returns 400 when required fields are missing" do
      conn =
        conn(:post, "/publish", ~s({"exchange": "test_exchange"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 400
    end
  end
end
