defmodule Exco.Resolver do
  @moduledoc false

  def get_result(result, _enumerable, :map, link) do
    result
    |> Enum.map(&get_map_value(&1, link))
  end

  def get_result(result, _enumerable, :each, _link) do
    result
    |> Enum.each(fn value -> value end)
  end

  def get_result(result, enumerable, :filter, link) do
    result
    |> Enum.zip(enumerable)
    |> get_filter_values(link)
    |> Enum.reverse()
  end

  def get_result(result, _enumerable, :stream_map, link) do
    result
    |> Stream.map(&get_map_value(&1, link))
  end

  defp get_map_value(value, false), do: value
  defp get_map_value({:ok, value}, true), do: value
  defp get_map_value(value, _link), do: value

  defp get_filter_values(enum, false) do
    Enum.reduce(enum, [], fn res, acc ->
      case res do
        {{:ok, true}, val} -> [val | acc]
        {{:ok, false}, _val} -> acc
        {_result, _val} -> acc
      end
    end)
  end

  defp get_filter_values(enum, true) do
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
