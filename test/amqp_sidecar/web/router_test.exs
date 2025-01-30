# test/amqp_sidecar/web/router_test.exs
defmodule AmqpSidecar.Web.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias AmqpSidecar.Web.Router

  @opts Router.init([])

  describe "POST /publish" do
    test "publishes a message to an AMQP exchange" do
      conn = conn(:post, "/publish", ~s({"exchange": "test_exchange", "routingKey": "test_key", "message": "test_message"}))
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

      assert conn.status == 200
      assert conn.response_body == "Message published"
    end

    test "returns 400 for invalid JSON payload" do
      conn = conn(:post, "/publish", "invalid_json")
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

      assert conn.status == 400
      assert conn.response_body == "Invalid JSON payload"
    end
  end
end
