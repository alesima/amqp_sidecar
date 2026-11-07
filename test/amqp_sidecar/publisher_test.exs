defmodule AmqpSidecar.PublisherTest do
  use ExUnit.Case, async: true
  import Mox

  alias AmqpSidecar.Broker.Mock, as: BrokerMock

  setup :verify_on_exit!

  setup do
    AmqpSidecar.Metrics.setup()
    :ok
  end

  describe "publish/4" do
    test "publishes a message to an AMQP exchange" do
      expect(BrokerMock, :open_connection, fn _ -> {:ok, :mock_conn} end)
      expect(BrokerMock, :open_channel, fn :mock_conn -> {:ok, :mock_chan} end)

      expect(BrokerMock, :publish, fn :mock_chan,
                                      "test_exchange",
                                      "test_key",
                                      "test_message",
                                      _opts ->
        :ok
      end)

      expect(BrokerMock, :close_channel, fn :mock_chan -> :ok end)
      expect(BrokerMock, :close_connection, fn :mock_conn -> :ok end)

      assert :ok = AmqpSidecar.Publisher.publish("test_exchange", "test_key", "test_message")
    end

    test "returns an error when the connection fails" do
      expect(BrokerMock, :open_connection, fn _ -> {:error, :econnrefused} end)

      assert {:error, :econnrefused} =
               AmqpSidecar.Publisher.publish("test_exchange", "test_key", "test_message")
    end

    test "returns an error when publishing fails" do
      expect(BrokerMock, :open_connection, fn _ -> {:ok, :mock_conn} end)
      expect(BrokerMock, :open_channel, fn :mock_conn -> {:ok, :mock_chan} end)
      expect(BrokerMock, :publish, fn _, _, _, _, _ -> {:error, :closed} end)

      assert {:error, :closed} =
               AmqpSidecar.Publisher.publish("test_exchange", "test_key", "test_message")
    end
  end
end
