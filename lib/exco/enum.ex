defmodule Exco.Enum do

  def task_func(_max_conc = :full), do: &awaited_map/3
  def task_func(_max_conc),         do: &async_stream/3

  def async_stream(enumerable, fun, options) do
    enumerable
    |> Task.async_stream(fun, options)
  end

  def awaited_map(enumerable, fun, _options \\ []) do
    enumerable
    |> Enum.map(&(Task.async(fn -> fun.(&1) end)))
    |> Enum.map(&Task.await/1)
  end
end
