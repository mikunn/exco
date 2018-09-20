defmodule Exco.Runner do
  @moduledoc false

  alias Exco.{Opts, Resolver, Runner}

  defmacro run(operation, enumerable, fun, opts) do
    quote do
      opts =
        Opts.set_defaults((unquote opts), @default_options)
        |> Enum.into(%{})

      operation = unquote operation
      enumerable = unquote enumerable

      {caller, arity} = unquote(__CALLER__.function)

      link = Runner.link?(caller)

      enumerable
      |> Runner.enumerate((unquote fun), link, opts)
      |> Resolver.get_result(enumerable, operation, link)
    end
  end

  def enumerate(enumerable, fun, true = _link, options) do
    enumerate_link(enumerable, fun, options)
  end

  def enumerate(enumerable, fun, false = _link, options) do
    enumerate_nolink(enumerable, fun, options)
  end

  def link?(fun) do
    fun
    |> Atom.to_string
    |> String.ends_with?("_nolink")
    |> Kernel.not
  end

  defp enumerate_link(enumerable, fun, %{max_concurrency: :full}) do
    awaited_map(enumerable, fun)
  end

  defp enumerate_link(enumerable, fun, %{max_concurrency: :schedulers} = options) do
    opts = [
      max_concurrency: resolve_max_concurrency(:schedulers, enumerable),
      ordered: options[:ordered]
    ]

    async_stream(enumerable, fun, opts)
  end

  defp enumerate_link(enumerable, fun, %{max_concurrency: conc} = options) do
    opts = [
      max_concurrency: conc,
      ordered: options[:ordered]
    ]

    async_stream(enumerable, fun, opts)
  end

  defp enumerate_nolink(enumerable, fun, options) do
    conc =
      case options[:max_concurrency] do
        :schedulers -> resolve_max_concurrency(:schedulers, enumerable)
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

  defp resolve_max_concurrency(:schedulers, _enumerable), do: System.schedulers_online()
  defp resolve_max_concurrency(:full, enumerable) do
    case Enum.count(enumerable) do
      0 -> System.schedulers_online()
      count -> count
    end
  end
end
