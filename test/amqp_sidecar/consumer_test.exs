# test/amqp_sidecar/consumer_test.exs
defmodule AmqpSidecar.ConsumerTest do
  use ExUnit.Case, async: true
  import Mox

  alias AMQP.{Connection, Channel}

  setup :verify_on_exit!

  describe "init/1" do
    test "sets up consumers based on the configuration" do
      expect(Connection.mock(), :open, fn _ -> {:ok, :mock_conn} end)
      expect(Channel.mock(), :open, fn :mock_conn -> {:ok, :mock_chan} end)
      expect(Channel.mock(), :topic, fn :mock_chan, "test_exchange", _ -> :ok end)
      expect(Channel.mock(), :declare, fn :mock_chan, "test_queue", _ -> :ok end)
      expect(Channel.mock(), :bind, fn :mock_chan, "test_queue", "test_exchange", _ -> :ok end)
      expect(Channel.mock(), :consume, fn :mock_chan, "test_queue", _ -> :ok end)

      config = %{
        rules: [
          %{
            exchange: "test_exchange",
            queue: "test_queue",
            routingKeys: ["test.*"],
            endpointUri: "http://test-endpoint"
          }
        ]
      }

      assert {:ok, %{conn: :mock_conn, chan: :mock_chan}} = AmqpSidecar.Consumer.init(config)
    end
  end
end
