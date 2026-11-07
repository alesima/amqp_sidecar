defmodule AmqpSidecar.ConsumerTest do
  use ExUnit.Case, async: true
  import Mox

  alias AmqpSidecar.Broker.Mock, as: BrokerMock
  alias AmqpSidecar.Http.Mock, as: HttpMock

  setup :verify_on_exit!

  setup do
    AmqpSidecar.Metrics.setup()
    :ok
  end

  @config %{
    "rules" => [
      %{
        "exchange" => "test_exchange",
        "exchangeType" => "topic",
        "queue" => "test_queue",
        "routingKeys" => ["test.*"],
        "endpointUri" => "http://test-endpoint"
      }
    ]
  }

  defp expect_setup(chan \\ :mock_chan) do
    expect(BrokerMock, :declare_exchange, fn ^chan, "test_exchange", "topic", [durable: true] ->
      :ok
    end)

    expect(BrokerMock, :declare_queue, fn ^chan, "test_queue", [durable: true] -> {:ok, %{}} end)

    expect(BrokerMock, :bind_queue, fn ^chan,
                                       "test_queue",
                                       "test_exchange",
                                       [routing_key: "test.*"] ->
      :ok
    end)

    expect(BrokerMock, :consume, fn ^chan, "test_queue" -> {:ok, "tag-1"} end)
  end

  describe "init/1" do
    test "sets up consumers based on the configuration" do
      expect(BrokerMock, :open_connection, fn "amqp://guest:guest@localhost:5672/" ->
        {:ok, :mock_conn}
      end)

      expect(BrokerMock, :open_channel, fn :mock_conn -> {:ok, :mock_chan} end)
      expect_setup()

      assert {:ok, %AmqpSidecar.Consumer{chan: :mock_chan}} = AmqpSidecar.Consumer.init(@config)
    end

    test "stops when the connection fails" do
      expect(BrokerMock, :open_connection, fn _ -> {:error, :econnrefused} end)

      assert {:stop, :econnrefused} = AmqpSidecar.Consumer.init(@config)
    end
  end

  describe "topic_match?/2" do
    test "star matches exactly one word" do
      assert AmqpSidecar.Consumer.topic_match?("test.*", "test.key")
      refute AmqpSidecar.Consumer.topic_match?("test.*", "test.a.b")
      refute AmqpSidecar.Consumer.topic_match?("test.*", "test")
    end

    test "hash matches zero or more words" do
      assert AmqpSidecar.Consumer.topic_match?("test.#", "test.key")
      assert AmqpSidecar.Consumer.topic_match?("test.#", "test.a.b")
      assert AmqpSidecar.Consumer.topic_match?("#", "anything.at.all")
    end

    test "exact segments must be equal" do
      assert AmqpSidecar.Consumer.topic_match?("a.b.c", "a.b.c")
      refute AmqpSidecar.Consumer.topic_match?("a.b.c", "a.b.d")
    end
  end

  describe "match_rule/3" do
    test "finds the rule by exchange and pattern" do
      rules = [%{exchange: "ex", queue: "q", patterns: ["test.*"], endpoint: "http://e"}]

      assert %{queue: "q"} = AmqpSidecar.Consumer.match_rule(rules, "ex", "test.key")
      assert nil == AmqpSidecar.Consumer.match_rule(rules, "other", "test.key")
      assert nil == AmqpSidecar.Consumer.match_rule(rules, "ex", "test.a.b")
    end
  end

  describe "handle_info :basic_deliver" do
    setup do
      state = %AmqpSidecar.Consumer{
        conn: :mock_conn,
        chan: :mock_chan,
        rules: [
          %{
            exchange: "test_exchange",
            queue: "test_queue",
            patterns: ["test.*"],
            endpoint: "http://test-endpoint"
          }
        ]
      }

      {:ok, state: state}
    end

    test "forwards, acks on success", %{state: state} do
      expect(HttpMock, :post, fn "http://test-endpoint", "hello", _headers ->
        {:ok, %{status_code: 200}}
      end)

      expect(BrokerMock, :ack, fn :mock_chan, 1 -> :ok end)

      meta = %{exchange: "test_exchange", routing_key: "test.key", delivery_tag: 1}

      assert {:noreply, ^state} =
               AmqpSidecar.Consumer.handle_info({:basic_deliver, "hello", meta}, state)
    end

    test "rejects with requeue on endpoint error", %{state: state} do
      expect(HttpMock, :post, fn _, _, _ -> {:ok, %{status_code: 500}} end)
      expect(BrokerMock, :reject, fn :mock_chan, 1, [requeue: true] -> :ok end)

      meta = %{exchange: "test_exchange", routing_key: "test.key", delivery_tag: 1}

      assert {:noreply, ^state} =
               AmqpSidecar.Consumer.handle_info({:basic_deliver, "hello", meta}, state)
    end

    test "rejects with requeue on connection failure", %{state: state} do
      expect(HttpMock, :post, fn _, _, _ -> {:error, :econnrefused} end)
      expect(BrokerMock, :reject, fn :mock_chan, 1, [requeue: true] -> :ok end)

      meta = %{exchange: "test_exchange", routing_key: "test.key", delivery_tag: 1}

      assert {:noreply, ^state} =
               AmqpSidecar.Consumer.handle_info({:basic_deliver, "hello", meta}, state)
    end

    test "acks and drops messages with no matching rule", %{state: state} do
      expect(BrokerMock, :ack, fn :mock_chan, 1 -> :ok end)

      meta = %{exchange: "test_exchange", routing_key: "unknown.key.extra", delivery_tag: 1}

      assert {:noreply, ^state} =
               AmqpSidecar.Consumer.handle_info({:basic_deliver, "hello", meta}, state)
    end
  end

  describe "handle_info control messages" do
    test "consume_ok keeps running" do
      state = %AmqpSidecar.Consumer{}

      assert {:noreply, ^state} =
               AmqpSidecar.Consumer.handle_info({:basic_consume_ok, %{consumer_tag: "t"}}, state)
    end

    test "cancel stops normally" do
      state = %AmqpSidecar.Consumer{}

      assert {:stop, :normal, ^state} =
               AmqpSidecar.Consumer.handle_info({:basic_cancel, %{consumer_tag: "t"}}, state)
    end
  end
end
