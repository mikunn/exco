defmodule Exco do

  alias Exco.Opts

  @default_options [
    max_concurrency: :full
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
    opts = Opts.set_defaults(opts, @default_options)
           |> Enum.into(%{})
    enumerate(operation, enumerable, fun, opts)
  end

  defp enumerate(:map, enumerable, fun, %{max_concurrency: conc}) when conc == :full do
    get_awaited_map(enumerable, fun)
  end

  defp enumerate(:map, enumerable, fun, %{max_concurrency: conc}) do
    get_async_stream(enumerable, fun, max_concurrency: conc)
    |> Enum.map(fn {:ok, value} -> value end)
  end

  defp enumerate(:each, enumerable, fun, %{max_concurrency: conc}) when conc == :full do
    get_awaited_map(enumerable, fun)
    |> Enum.each(fn value -> value end)
  end

  defp enumerate(:each, enumerable, fun, %{max_concurrency: conc}) do
    get_async_stream(enumerable, fun, max_concurrency: conc)
    |> Enum.each(fn value -> value end)
  end

  defp enumerate(:filter, enumerable, fun, %{max_concurrency: conc}) when conc == :full do
    get_awaited_map(enumerable, fun)
    |> Enum.zip(enumerable)
    |> Enum.filter(fn res ->
      case res do
        {true, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {true, value} -> value end)
  end

  defp enumerate(:filter, enumerable, fun, %{max_concurrency: conc}) do
    get_async_stream(enumerable, fun, max_concurrenct: conc)
    |> Enum.zip(enumerable)
    |> Enum.filter(fn res ->
      case res do
        {{:ok, true}, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {{:ok, true}, value} -> value end)
  end

  defp get_async_stream(enumerable, fun, options) do
    enumerable
    |> Task.async_stream(fun, options)
  end

  defp get_awaited_map(enumerable, fun) do
    enumerable
    |> Enum.map(&(Task.async(fn -> fun.(&1) end)))
    |> Enum.map(&Task.await/1)
  end

end
