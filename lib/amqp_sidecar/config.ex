# lib/amqp_sidecar/config.ex
defmodule AmqpSidecar.Config do
  @moduledoc """
  Parses and validates the broker.json configuration
  """

  @config_path Application.compile_env(:amqp_sidecar, :config_path)

  def load_config do
    case File.read(@config_path) do
      {:ok, content} ->
        Jason.decode!(content)

      {:error, reason} ->
        raise "Failed to load config: #{reason}"
    end
  end

  def validate_config(config) do
    rules = config["rules"] || raise "Missing 'rules' in config"

    Enum.each(rules, fn rule ->
      unless rule["exchange"] && rule["queue"] && rule["routingKeys"] && rule["endpointUri"] do
        raise "Invalid rule: #{inspect(rule)}"
      end
    end)

    config
  end
end
