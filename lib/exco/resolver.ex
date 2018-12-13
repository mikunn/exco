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

  def get_result(result, enumerable, :filter, _link) do
    result
    |> Enum.zip(enumerable)
    |> get_filter_values()
    |> Enum.reverse()
  end

  def get_result(result, _enumerable, :stream_map, link) do
    result
    |> Stream.map(&get_map_value(&1, link))
  end

  defp get_map_value({:ok, value}, true), do: {:ok, value}
  defp get_map_value(value, _link), do: value

  defp get_filter_values(enum) do
    Enum.reduce(enum, [], fn res, acc ->
      case res do
        {{:ok, true}, val} -> [{:ok, val} | acc]
        _other -> acc
      end
    end)
  end
end
