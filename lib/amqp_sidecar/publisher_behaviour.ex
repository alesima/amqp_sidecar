defmodule AmqpSidecar.PublisherBehaviour do
  @moduledoc """
  Behaviour for message publishing, allowing the HTTP layer to be tested
  with `AmqpSidecar.Publisher.Mock` (Mox).
  """

  @callback publish(String.t(), String.t(), String.t(), map() | list()) ::
              :ok | {:error, term()}
end
