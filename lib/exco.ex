defmodule Exco do
  alias Exco.Opts

  @default_options [
    max_concurrency: :auto,
    linkage: :link
  ]

  def map(enumerable, fun, opts \\ []) do
    run(:map, enumerable, fun, opts)
  end

  def each(enumerable, fun, opts \\ []) do
    run(:each, enumerable, fun, opts)
  end

  def filter(enumerable, fun, opts \\ []) do
    run(:filter, enumerable, fun, opts)
  end

  defp run(operation, enumerable, fun, opts) do
    opts =
      Opts.set_defaults(opts, @default_options)
      |> Enum.into(%{})

    enumerate(operation, enumerable, fun, opts)
  end

  defp enumerate(:map, enumerable, fun, options) do
    Exco.Enum.results(enumerable, fun, options)
    |> Enum.map(&resolve_map_value(&1, options))
  end

  defp enumerate(:each, enumerable, fun, options) do
    Exco.Enum.results(enumerable, fun, options)
    |> Enum.each(fn value -> value end)
  end

  defp enumerate(:filter, enumerable, fun, options) do
    Exco.Enum.results(enumerable, fun, options)
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
