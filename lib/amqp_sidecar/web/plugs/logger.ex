# lib/amqp_sidecar/web/plugs/logger.ex
defmodule AmqpSidecar.Web.Plugs.Logger do
  @moduledoc """
  Logs incoming requests
  """

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    start_time = System.monotonic_time()

    conn
    |> register_before_send(&log_response(&1, start_time))
  end

  defp log_response(conn, start_time) do
    end_time = System.monotonic_time()
    diff = System.convert_time_unit(end_time - start_time, :native, :millisecond)

    Logger.info("#{conn.method} #{conn.request_path} - #{conn.status} - #{diff}ms")

    conn
  end
end
