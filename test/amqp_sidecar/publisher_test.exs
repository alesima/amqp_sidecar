# test/amqp_sidecar/publisher_test.exs
defmodule AmqpSidecar.PublisherTest do
  use ExUnit.Case, async: true
  import Mox

  alias AMQP.{Connection, Channel}

  setup :verify_on_exit!

  describe "publish/4" do
    test "publishes a message to an AMQP exchange" do
      expect(Connection.mock(), :open, fn _ -> {:ok, :mock_conn} end)
      expect(Channel.mock(), :open, fn :mock_conn -> {:ok, :mock_chan} end)
      expect(Channel.mock(), :publish, fn :mock_conn, :mock_chan, "test_exchange", "test_key", "test_message", _ -> :ok end)

      assert :ok = AmqpSidecar.Publisher.publish("test_exchange", "test_key", "test_message")
    end
  end
end
