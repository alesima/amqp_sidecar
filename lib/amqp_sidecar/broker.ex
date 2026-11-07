defmodule AmqpSidecar.Broker do
  @moduledoc """
  Behaviour abstracting the AMQP client.

  The production implementation (`AmqpSidecar.Broker.AMQP`) talks to RabbitMQ.
  Tests inject `AmqpSidecar.Broker.Mock` (Mox) via
  `Application.get_env(:amqp_sidecar, :broker)`.
  """

  @type connection :: term()
  @type channel :: term()

  @callback open_connection(String.t()) :: {:ok, connection()} | {:error, term()}
  @callback open_channel(connection()) :: {:ok, channel()} | {:error, term()}
  @callback declare_exchange(channel(), String.t(), String.t(), keyword()) ::
              :ok | {:error, term()}
  @callback declare_queue(channel(), String.t(), keyword()) ::
              {:ok, map()} | {:error, term()}
  @callback bind_queue(channel(), String.t(), String.t(), keyword()) ::
              :ok | {:error, term()}
  @callback consume(channel(), String.t()) :: {:ok, String.t()} | {:error, term()}
  @callback publish(channel(), String.t(), String.t(), String.t(), keyword()) ::
              :ok | {:error, term()}
  @callback ack(channel(), non_neg_integer()) :: :ok | {:error, term()}
  @callback reject(channel(), non_neg_integer(), keyword()) :: :ok | {:error, term()}
  @callback close_channel(channel()) :: :ok | {:error, term()}
  @callback close_connection(connection()) :: :ok | {:error, term()}
end
