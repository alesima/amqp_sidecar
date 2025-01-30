# test/amqp_sidecar/config_test.exs
defmodule AmqpSidecar.ConfigTest do
  use ExUnit.Case, async: true

  describe "load_config/0" do
    test "loads and validates the configuration" do
      config_content = """
      {
        "rules": [
          {
            "exchange": "test_exchange",
            "queue": "test_queue",
            "routingKeys": ["test.*"],
            "endpointUri": "http://test-endpoint"
          }
        ]
      }
      """

      File.write("test_config.json", config_content)

      Application.put_env(:amqp_sidecar, :config_path, "test_config.json")

      config = AmqpSidecar.Config.load_config() |> AmqpSidecar.Config.validate_config()

      assert config["rules"] == [
               %{
                 "exchange" => "test_exchange",
                 "queue" => "test_queue",
                 "routingKeys" => ["test.*"],
                 "endpointUri" => "http://test-endpoint"
               }
             ]

      File.rm("test_config.json")
    end

    test "raises an error if the configuration is invalid" do
      config_content = """
      {
        "rules": [
          {
            "exchange": "test_exchange",
            "queue": "test_queue",
          }
        ]
      }
      """

      File.write("test_config.json", config_content)

      Application.put_env(:amqp_sidecar, :config_path, "test_config.json")

      assert_raise RuntimeError, ~r/Missing 'endpointUri' in config/, fn ->
        AmqpSidecar.Config.load_config() |> AmqpSidecar.Config.validate_config()
      end

      File.rm("test_config.json")
    end
  end
end
