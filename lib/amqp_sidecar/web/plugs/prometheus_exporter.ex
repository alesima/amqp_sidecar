# lib/amqp_sidecar/web/plugs/prometheus_exporter.ex
defmodule AmqpSidecar.Web.Plugs.PrometheusExporter do
  use Prometheus.PlugExporter

  def init(opts), do: opts

  def metrics(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, Prommetheus.TextFormat.format())
  end
end
