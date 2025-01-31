# lib/amqp_sidecar/metrics.ex
defmodule AmqpSidecar.Metrics do
  @moduledoc """
  Metrics for the application
  """
  use Prometheus.Metric

  def setup() do
    Counter.declare(
      name: :http_requests_total,
      help: "HTTP request count",
      labels: [:method, :status]
    )

    Histogram.declare(
      name: :http_request_duration_seconds,
      help: "HTTP request duration in seconds",
      labels: [:method, :status],
      buckets: [0.1, 0.5, 1, 2, 5]
    )

    # RabbitMQ specific metrics
    Gauge.declare(
      name: :rabbitmq_connections,
      help: "Current number of RabbitMQ connections",
      labels: [:host]
    )

    Counter.declare(
      name: :rabbitmq_messages_published_total,
      help: "Total number of messages published",
      labels: [:exchange]
    )

    Counter.declare(
      name: :rabbitmq_messages_delivered_total,
      help: "Total number of messages delivered",
      labels: [:queue]
    )

    Gauge.declare(
      name: :rabbitmq_queue_messages,
      help: "Number of messages in queue",
      labels: [:queue]
    )

    Summary.declare(
      name: :rabbitmq_message_delivery_time,
      help: "Time taken to deliver messages to consumers",
      labels: [:queue]
    )
  end

  def increment_request(method, status) do
    Counter.inc(name: :http_requests_total, labels: [method, status])
  end

  def observe_request_duration(method, status, duration) do
    Histogram.observe([name: :http_request_duration_seconds, labels: [method, status]], duration)
  end

  def update_connections(host, count) do
    Gauge.set([name: :rabbitmq_connections, labels: [host]], count)
  end

  def increment_messages_published(exchange) do
    Counter.inc(name: :rabbitmq_messages_published_total, labels: [exchange])
  end

  def increment_messages_delivered(queue) do
    Counter.inc(name: :rabbitmq_messages_delivered_total, labels: [queue])
  end

  def update_queue_messages(queue, count) do
    Gauge.set([name: :rabbitmq_queue_messages, labels: [queue]], count)
  end

  def observe_message_delivery_time(queue, duration) do
    Summary.observe([name: :rabbitmq_message_delivery_time, labels: [queue]], duration)
  end
end
