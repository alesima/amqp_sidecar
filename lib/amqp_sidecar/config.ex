defmodule AmqpSidecar.Config do
  @moduledoc """
  Parses and validates the broker.json configuration
  """

  @exchange_types ~w(topic direct fanout x-delayed-message)

  def load_config do
    path = Application.get_env(:amqp_sidecar, :config_path)

    case File.read(path) do
      {:ok, content} ->
        Jason.decode!(content)

      {:error, :enoent} ->
        raise "Missing config file: #{path}"

      {:error, reason} ->
        raise "Failed to load config: #{inspect(reason)}"
    end
  end

  def validate_config(config) do
    rules = config["rules"] || raise "Missing 'rules' in config"

    unless is_list(rules) do
      raise "Invalid config: 'rules' must be a list"
    end

    Enum.each(rules, &validate_rule!/1)

    config
  end

  defp validate_rule!(rule) do
    for key <- ~w(exchange queue routingKeys endpointUri) do
      unless rule[key] do
        raise "Invalid rule (missing '#{key}'): #{inspect(rule)}"
      end
    end

    unless is_list(rule["routingKeys"]) do
      raise "Invalid rule ('routingKeys' must be a list): #{inspect(rule)}"
    end

    if type = rule["exchangeType"] do
      unless type in @exchange_types do
        raise "Invalid rule (unknown exchangeType '#{type}'): #{inspect(rule)}"
      end

      if type == "x-delayed-message" do
        args = rule["exchangeArguments"] || %{}

        unless args["x-delayed-type"] do
          raise "Invalid rule (x-delayed-message requires exchangeArguments.x-delayed-type): #{inspect(rule)}"
        end
      end
    end

    :ok
  end
end
