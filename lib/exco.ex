defmodule Exco do
  @moduledoc ~S"""

  Functions to run things concurrently.

  See further discussion in the [readme section](readme.html).

  ## Options

  * `max_concurrency` - the maximum number of items to run at the same time. Set it to an integer or one of the following:
    * `:schedulers` (default) - set to `System.schedulers_online/1`
    * `:full` - tries to run all items at the same time

  """

  alias Exco.{Opts, Resolver, Runner}

  @default_options [
    max_concurrency: :schedulers,
    ordered: true
  ]

  @doc ~S"""
  Concurrent version of `Enum.map/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will be linked.

  The return value is a list where each item is a result of invoking `fun` on each
  corresponding item of `enumerable`.

  * a list consisting of either `{:ok, value}` or `{:exit, reason}` tuples (when `link: false`).

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.map(1..3, fn x -> x*2 end)
      [2, 4, 6]

  """
  def map(enumerable, fun, opts \\ []) do
    run(:map, true, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.map/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will not be linked.

  The return value is a list consisting of either `{:ok, value}` or `{:exit, reason}` tuples.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.map_nolink(1..3, fn x -> x*2 end)
      [ok: 2, ok: 4, ok: 6]

  """
  def map_nolink(enumerable, fun, opts \\ []) do
    run(:map, false, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.each/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will be linked.

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
    run(:each, true, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.each/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will not be linked.

  Returns `:ok`.

  See the [options](#module-options).

  ## Examples

      Exco.each_nolink(1..3, fn x -> IO.puts x*2 end)
      2
      4
      6
      #=> :ok

  """
  def each_nolink(enumerable, fun, opts \\ []) do
    run(:each, false, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.filter/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will be linked.

  The return value is a list and consists of the original
  values for which the applied function returns a truthy value.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.filter(1..3, fn x -> x < 3 end)
      [1, 2]

  """
  def filter(enumerable, fun, opts \\ []) do
    run(:filter, true, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.filter/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will not be linked.

  The return value is the same as in the case of `Exco.filter/3`.
  Thus, falsy return values from the function or failing task processes are ignored.
  No indication is provided whether a value was dropped due to it being falsy or
  because of a failing process.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.filter_nolink(1..3, fn x -> x < 3 end)
      [1, 2]

  """
  def filter_nolink(enumerable, fun, opts \\ []) do
    run(:filter, false, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Stream.map/2`.

  Returns a stream that concurrently calls `fun` for each item in `enumerable`.
  This is similar to `Exco.map/3`, but lazily iterates through `enumerable`.
  The caller and the spawned processes will be linked.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> stream = Exco.stream_map(1..3, fn x -> x*2 end)
      iex(2)> Enum.to_list(stream)
      [2, 4, 6]

  """
  def stream_map(enumerable, fun, opts \\ []) do
    run(:stream_map, true, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Stream.map/2`.

  Returns a stream that concurrently calls `fun` for each item in `enumerable`.
  This is similar to `Exco.map_nolink/3`, but lazily iterates through `enumerable`.
  The caller and the spawned processes will not be linked.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> stream = Exco.stream_map_nolink(1..3, fn x -> x*2 end)
      iex(2)> Enum.to_list(stream)
      [ok: 2, ok: 4, ok: 6]

  """
  def stream_map_nolink(enumerable, fun, opts \\ []) do
    run(:stream_map, false, enumerable, fun, opts)
  end

  defp run(operation, link, enumerable, fun, opts) do
    opts =
      Opts.set_defaults(opts, @default_options)
      |> Enum.into(%{})

    enumerable
    |> Runner.enumerate(fun, link, opts)
    |> Resolver.get_result(enumerable, operation, link)
  end
end
