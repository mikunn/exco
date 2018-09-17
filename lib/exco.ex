defmodule Exco do
  @moduledoc ~S"""

  Functions to run things concurrently.

  See further discussion in the [readme section](readme.html).

  ## Options

  * `link` - set this to `false` to not link the spawned processes with the caller. Defaults to `true`.
  * `max_concurrency` - the maximum number of items to run at the same time. Set it to an integer or one of the following:
    * `:schedulers` (default) - set to `System.schedulers_online/1`
    * `:full` - tries to run all items at the same time

  """

  alias Exco.{Opts, Resolver, Runner}

  @default_options [
    max_concurrency: :schedulers,
    link: true,
    ordered: true
  ]

  @doc ~S"""
  Concurrent version of `Enum.map/2`.

  The applied function runs in a new process for each item.

  Depending on the value of `link` option, the result value is either

  * a list of result values (when `link: true`)
  * a list consisting of either `{:ok, value}` or `{:exit, reason}` tuples (when `link: false`).

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.map(1..3, fn x -> x*2 end)
      [2, 4, 6]

  """
  def map(enumerable, fun, opts \\ []) do
    run(:map, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.each/2`.

  The applied function runs in a new process for each item.
  Returns `:ok`.

  See the [options](#module-options).

  ## Examples

      Exco.each(1..3, fn x -> IO.puts x*2 end)
      2
      4
      6
      #=> :ok

  """
  def each(enumerable, fun, opts \\ []) do
    run(:each, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.filter/2`.

  The applied function runs in a new process for each item.

  When `link: true`, the return value is a list and consists of the original
  values for which the applied function returns a truthy value.

  When `link: false`, the return value is the same as in the case `link: true`.
  Thus, falsy return values from the function or failing task processes are ignored.
  No indication is provided whether a value was dropped due to it being falsy or
  because of a failing process.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.filter(1..3, fn x -> x < 3 end)
      [1, 2]

  """
  def filter(enumerable, fun, opts \\ []) do
    run(:filter, enumerable, fun, opts)
  end

  defp run(operation, enumerable, fun, opts) do
    opts =
      Opts.set_defaults(opts, @default_options)
      |> Enum.into(%{})

    enumerable
    |> Runner.enumerate(fun, opts)
    |> Resolver.get_result(enumerable, operation, opts)
  end
end
