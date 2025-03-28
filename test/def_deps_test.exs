defmodule DefDepsTest do
  use ExUnit.Case
  doctest DefDeps

  test "greets the world" do
    assert DefDeps.hello() == :world
  end
end
