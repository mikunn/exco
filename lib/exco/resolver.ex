defmodule Exco.Resolver do
  @moduledoc false

  def get_result(result, _enumerable, :map, options) do
    result
    |> Enum.map(&get_map_value(&1, options))
  end

  def get_result(result, _enumerable, :each, _options) do
    result
    |> Enum.each(fn value -> value end)
  end

  def get_result(result, enumerable, :filter, options) do
    result
    |> Enum.zip(enumerable)
    |> get_filter_values(options)
    |> Enum.reverse()
  end

  defp get_map_value(value, %{link: false}), do: value
  defp get_map_value({:ok, value}, %{link: true}), do: value
  defp get_map_value(value, _options), do: value

  defp get_filter_values(enum, %{link: false}) do
    Enum.reduce(enum, [], fn res, acc ->
      case res do
        {{:ok, true}, val} -> [val | acc]
        {{:ok, false}, _val} -> acc
        {_result, _val} -> acc
      end
    end)
  end

  defp get_filter_values(enum, %{link: true}) do
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
