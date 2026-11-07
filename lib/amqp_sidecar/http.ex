defmodule AmqpSidecar.Http do
  @moduledoc """
  Behaviour abstracting outbound HTTP calls (message forwarding).

  Production uses `AmqpSidecar.Http.HTTPoison`. Tests inject
  `AmqpSidecar.Http.Mock` (Mox) via
  `Application.get_env(:amqp_sidecar, :http_client)`.
  """

  @callback post(String.t(), String.t(), list()) ::
              {:ok, %{status_code: integer()}} | {:error, term()}

  defmodule HTTPoison do
    @moduledoc false
    @behaviour AmqpSidecar.Http

    @impl true
    def post(url, body, headers) do
      case Elixir.HTTPoison.post(url, body, headers) do
        {:ok, %Elixir.HTTPoison.Response{status_code: code}} -> {:ok, %{status_code: code}}
        {:error, %Elixir.HTTPoison.Error{reason: reason}} -> {:error, reason}
      end
    end
  end
end
