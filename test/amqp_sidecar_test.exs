defmodule AmqpSidecarTest do
  use ExUnit.Case
  doctest AmqpSidecar

  test "greets the world" do
    assert AmqpSidecar.hello() == :world
  end
end
