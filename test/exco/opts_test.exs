defmodule Exco.OptsTest do
  use ExUnit.Case
  doctest Exco

  test "setting defaults" do
    assert Exco.Opts.set_defaults() == []
    assert Exco.Opts.set_defaults([], []) == []
    assert Exco.Opts.set_defaults([], some_opt: 1) == [some_opt: 1]

    options = [
      max_concurrency: 20,
      second_option: true,
      extra_option: :ignored
    ]

    default = [
      max_concurrency: :full,
      second_option: 100,
      third_option: false
    ]

    result = Exco.Opts.set_defaults(options, default) |> Enum.sort()

    expected =
      [
        max_concurrency: 20,
        second_option: true,
        third_option: false
      ]
      |> Enum.sort()

    assert result == expected
  end
end
