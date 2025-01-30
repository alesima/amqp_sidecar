# lib/amqp_sidecar/web/router.ex
defmodule AmqpSidecar.Web.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/health" do
    send_resp(conn, 200, "OK")
  end

  post "/publish" do
    AmqpSidecar.Web.Controllers.MessageController.publish(conn)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
