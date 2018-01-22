defmodule Exco.Enum do
  def results(enumerable, fun, %{max_concurrency: :full, linkage: :link}) do
    awaited_map(enumerable, fun)
  end

  def results(enumerable, fun, %{max_concurrency: conc, linkage: :link}) do
    async_stream(enumerable, fun, max_concurrency: conc)
  end

  def results(enumerable, fun, %{max_concurrency: conc, linkage: :nolink}) do
    async_stream_nolink(enumerable, fun, max_concurrency: conc)
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
