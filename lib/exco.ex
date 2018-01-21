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

  defp enumerate(:map, enumerable, fun, %{max_concurrency: conc}) do
    task_func = Exco.Enum.task_func(conc)

    task_func.(enumerable, fun, max_concurrency: conc)
    |> Enum.map(&resolve_map_value/1)
  end

  defp enumerate(:each, enumerable, fun, %{max_concurrency: conc}) do
    task_func = Exco.Enum.task_func(conc)

    task_func.(enumerable, fun, max_concurrency: conc)
    |> Enum.each(fn value -> value end)
  end

  defp enumerate(:filter, enumerable, fun, %{max_concurrency: conc}) do
    task_func = Exco.Enum.task_func(conc)

    task_func.(enumerable, fun, max_concurrency: conc)
    |> Enum.zip(enumerable)
    |> Enum.reduce([], fn res, acc ->
      case res do
        {true, val}           -> [val | acc]
        {{:ok, true}, val}    -> [val | acc]
        {false, _val}         -> acc
        {{:ok, false}, val}   -> acc
      end
    end)
    |> Enum.reverse
  end

  defp resolve_map_value({:ok, value}), do: value
  defp resolve_map_value(value),        do: value

end
