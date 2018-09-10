defmodule Exco do
  @moduledoc ~S"""

  Concurrent versions of some of the `Enum` functions
  spawning the tasks linked to the caller.

  See further discussion in the [readme section](readme.html).

  ## Options

  * `max_concurrency`: the maximum number of items to run concurrently.
    By default, spawns as many processes as there are items.

  """

  alias Exco.Opts

  @default_options [
    max_concurrency: :full,
    linkage: :link,
    ordered: true
  ]

  @doc ~S"""
  Concurrent version of `Enum.map/2`.

  The applied function runs in a new process for each item.
  These processes *are* linked to the caller.

  The return value is a list of result values.
  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.map(1..3, fn x -> x*2 end)
      [2, 4, 6]

  """
  def map(enumerable, fun, opts \\ []) do
    run(:map, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.each/2`.

  The applied function runs in a new process for each item.
  These processes *are* linked to the caller.

  Returns `:ok`.

  See the [options](#module-options).

  ## Examples

      Exco.each(1..3, fn x -> IO.puts x*2 end)
      2 
      4 
      6
      #=> :ok

  """
  def each(enumerable, fun, opts \\ []) do
    run(:each, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.filter/2`.

  The applied function runs in a new process for each item.
  These processes *are* linked to the caller.

  The return value is a list and consists of the original
  values for which the applied function returns a truthy value.
  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.filter(1..3, fn x -> x < 3 end)
      [1, 2]

  """
  def filter(enumerable, fun, opts \\ []) do
    run(:filter, enumerable, fun, opts)
  end

  defp run(operation, enumerable, fun, opts) do
    opts =
      Opts.set_defaults(opts, @default_options)
      |> Enum.into(%{})

    enumerable
    |> Exco.Runner.enumerate(fun, opts)
    |> resolve_result(enumerable, operation, opts)
  end

  defp resolve_result(result, _enumerable, :map, options) do
    result
    |> Enum.map(&resolve_map_value(&1, options))
  end

  defp resolve_result(result, _enumerable, :each, _options) do
    result
    |> Enum.each(fn value -> value end)
  end

  defp resolve_result(result, enumerable, :filter, options) do
    result
    |> Enum.zip(enumerable)
    |> resolve_filter_values(options)
    |> Enum.reverse()
  end

  defp resolve_map_value(value, %{linkage: :nolink}), do: value
  defp resolve_map_value({:ok, value}, %{linkage: :link}), do: value
  defp resolve_map_value(value, _options), do: value

  defp resolve_filter_values(enum, %{linkage: :nolink}) do
    Enum.reduce(enum, [], fn res, acc ->
      case res do
        {{:ok, true}, val} -> [{:ok, val} | acc]
        {{:ok, false}, _val} -> acc
        {_result, _val} -> acc
      end
    end)
  end

  defp resolve_filter_values(enum, %{linkage: :link}) do
    Enum.reduce(enum, [], fn res, acc ->
      case res do
        {true, val} -> [val | acc]
        {{:ok, true}, val} -> [val | acc]
        {false, _val} -> acc
        {{:ok, false}, _val} -> acc
      end
    end)
  end
end
