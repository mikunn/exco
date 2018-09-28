defmodule Exco.Stream do
  @moduledoc ~S"""

  Concurrent versions of some of the functions in the `Stream` module.

  See further discussion in the [readme section](readme.html).

  ## Options

  * `max_concurrency` - the maximum number of items to run at the same time. Set it to an integer or one of the following:
    * `:schedulers` (default) - set to `System.schedulers_online/1`
    * `:full` - tries to run all items at the same time

  """

  import Exco.Runner, only: [run: 4]

  @default_options [
    max_concurrency: :schedulers,
    ordered: true
  ]

  @doc ~S"""
  Concurrent version of `Stream.map/2`.

  Returns a stream that concurrently calls `fun` for each item in `enumerable`.
  This is similar to `Exco.map/3`, but lazily iterates through `enumerable`.
  The caller and the spawned processes will be linked.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> stream = Exco.Stream.map(1..3, fn x -> x*2 end)
      iex(2)> Enum.to_list(stream)
      [2, 4, 6]

  """
  def map(enumerable, fun, opts \\ []) do
    run(:stream_map, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Stream.map/2`.

  Returns a stream that concurrently calls `fun` for each item in `enumerable`.
  This is similar to `Exco.map_nolink/3`, but lazily iterates through `enumerable`.
  The caller and the spawned processes will not be linked.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> stream = Exco.Stream.map_nolink(1..3, fn x -> x*2 end)
      iex(2)> Enum.to_list(stream)
      [ok: 2, ok: 4, ok: 6]

  """
  def map_nolink(enumerable, fun, opts \\ []) do
    run(:stream_map, enumerable, fun, opts)
  end
end
