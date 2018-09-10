defmodule Exco.Runner do
  @moduledoc false

  def enumerate(enumerable, fun, %{max_concurrency: :full, linkage: :link}) do
    awaited_map(enumerable, fun)
  end

  def enumerate(enumerable, fun, %{max_concurrency: :auto, linkage: :link} = options) do
    opts = [
      max_concurrency: resolve_max_concurrency(:auto, enumerable),
      ordered: options[:ordered]
    ]

    async_stream(enumerable, fun, opts)
  end

  def enumerate(enumerable, fun, %{max_concurrency: conc, linkage: :link} = options) do
    opts = [
      max_concurrency: conc,
      ordered: options[:ordered]
    ]

    async_stream(enumerable, fun, opts)
  end

  def enumerate(enumerable, fun, %{linkage: :nolink} = options) do
    conc =
      case options[:max_concurrency] do
        :auto -> resolve_max_concurrency(:auto, enumerable)
        :full -> resolve_max_concurrency(:full, enumerable)
        conc -> conc
      end

    opts = [
      max_concurrency: conc,
      ordered: options[:ordered]
    ]

    async_stream_nolink(enumerable, fun, opts)
  end

  defp async_stream(enumerable, fun, options) do
    Exco.TaskSupervisor
    |> Task.Supervisor.async_stream(enumerable, fun, options)
  end

  defp async_stream_nolink(enumerable, fun, options) do
    Exco.TaskSupervisor
    |> Task.Supervisor.async_stream_nolink(enumerable, fun, options)
  end

  defp awaited_map(enumerable, fun) do
    enumerable
    |> Enum.map(&Task.async(fn -> fun.(&1) end))
    |> Enum.map(&Task.await/1)
  end

  defp resolve_max_concurrency(:auto, _enumerable), do: System.schedulers_online()
  defp resolve_max_concurrency(:full, enumerable) do
    case Enum.count(enumerable) do
      0 -> System.schedulers_online()
      count -> count
    end
  end
end
