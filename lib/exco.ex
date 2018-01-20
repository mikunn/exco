defmodule Exco do

  def map(enumerable, fun) do
    enumerate(:map, enumerable, fun)
  end

  def each(enumerable, fun) do
    enumerate(:each, enumerable, fun)
  end

  def filter(enumerable, fun) do
    enumerate(:filter, enumerable, fun)
  end

  defp enumerate(:map, enumerable, fun) do
    get_stream(enumerable, fun)
    |> Enum.map(fn {:ok, value} -> value end)
  end

  defp enumerate(:each, enumerable, fun) do
    get_stream(enumerable, fun)
    |> Enum.each(fn value -> value end)
  end

  defp enumerate(:filter, enumerable, fun) do
    get_stream(enumerable, fun)
    |> Enum.zip(enumerable)
    |> Enum.filter(fn res -> 
      case res do
        {{:ok, true}, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {{:ok, true}, value} -> value end)
  end

  defp get_stream(enumerable, fun) do
    enumerable |> Task.async_stream(fun)
  end

end
