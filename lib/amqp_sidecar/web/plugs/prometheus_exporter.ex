# lib/amqp_sidecar/web/plugs/prometheus_exporter.ex
defmodule AmqpSidecar.Web.Plugs.PrometheusExporter do
  import Plug.Conn
  use Prometheus.PlugExporter
end
