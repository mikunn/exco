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
    opts = async_stream_options(options, enumerable)
    async_stream(enumerable, fun, opts)
  end

  def enumerate(enumerable, fun, false = _link, options) do
    opts = async_stream_options(options, enumerable)
    async_stream_nolink(enumerable, fun, opts)
  end

  def link?(fun) do
    fun
    |> Atom.to_string
    |> String.ends_with?("_nolink")
    |> Kernel.not
  end

  defp async_stream(enumerable, fun, options) do
    Exco.TaskSupervisor
    |> Task.Supervisor.async_stream(enumerable, fun, options)
  end

  defp async_stream_nolink(enumerable, fun, options) do
    Exco.TaskSupervisor
    |> Task.Supervisor.async_stream_nolink(enumerable, fun, options)
  end

  defp async_stream_options(%{max_concurrency: conc, ordered: ordered}, enumerable) do
    [
      max_concurrency: resolve_max_concurrency(conc, enumerable),
      ordered: ordered
    ]
  end

  defp resolve_max_concurrency(count, _enumerable) when is_integer(count), do: count
  defp resolve_max_concurrency(:schedulers, _enumerable), do: System.schedulers_online()
  defp resolve_max_concurrency(:full, enumerable) do
    case Enum.count(enumerable) do
      0 -> System.schedulers_online()
      count -> count
    end
  end

end
