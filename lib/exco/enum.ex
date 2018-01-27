defmodule Exco.Enum do
  @moduledoc false

  def results(enumerable, fun, %{max_concurrency: :auto, linkage: :link}) do
    awaited_map(enumerable, fun)
  end

  def results(enumerable, fun, %{max_concurrency: conc, linkage: :link} = options) do
    opts = [
      max_concurrency: conc,
      ordered: options[:ordered]
    ]

    async_stream(enumerable, fun, opts)
  end

  def results(enumerable, fun, %{linkage: :nolink} = options) do
    conc =
      case options[:max_concurrency] do
        :auto -> System.schedulers_online()
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
end
