defmodule ExcoTest do
  use ExUnit.Case
  doctest Exco

  test "greets the world" do
    assert Exco.hello() == :world
  end
end
