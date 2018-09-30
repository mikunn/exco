defmodule Exco do
  @moduledoc ~S"""

  Concurrent versions of some of the functions in the `Enum` module.

  See further discussion in the [readme section](readme.html).

  ## Options

  * `max_concurrency` - the maximum number of items to run at the same time. Set it to an integer or one of the following:
    * `:schedulers` (default) - set to `System.schedulers_online/1`
    * `:full` - tries to run all items at the same time

  """

  @type ok() :: {:ok, any}
  @type ex() :: {:ok, any}

  import Exco.Runner, only: [run: 4]

  @default_options [
    max_concurrency: :schedulers,
    ordered: true
  ]

  @doc ~S"""
  Concurrent version of `Enum.map/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will be linked.

  The return value is a list of either `{:ok, value}` or
  `{:exit, reason}` if the caller is trapping exits. Each
  `value` is a result of invoking `fun` on each corresponding
  item of `enumerable`.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.map(1..3, fn x -> x*2 end)
      [ok: 2, ok: 4, ok: 6]

  """
  @spec map(Enumerable.t, (any -> any), keyword) :: [ok | ex]
  def map(enumerable, fun, opts \\ []) do
    run(:map, enumerable, fun, opts)
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
  @spec map_nolink(Enumerable.t, (any -> any), keyword) :: [ok | ex]
  def map_nolink(enumerable, fun, opts \\ []) do
    run(:map, enumerable, fun, opts)
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
  @spec each(Enumerable.t, (any -> any), keyword) :: :ok
  def each(enumerable, fun, opts \\ []) do
    run(:each, enumerable, fun, opts)
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
  @spec each_nolink(Enumerable.t, (any -> any), keyword) :: :ok
  def each_nolink(enumerable, fun, opts \\ []) do
    run(:each, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.filter/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will be linked.

  The return value is a list of `{:ok, value}` tuples where
  `value` is the original value for which the applied function
  returned a truthy value.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.filter(1..3, fn x -> x < 3 end)
      [ok: 1, ok: 2]

  """
  @spec filter(Enumerable.t, (any -> as_boolean(any)), keyword) :: [ok]
  def filter(enumerable, fun, opts \\ []) do
    run(:filter, enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.filter/2`.

  The applied function runs in a new process for each item.
  The caller and the spawned processes will not be linked.

  The return value is the same as in the case of `Exco.filter/3`.
  Thus, falsy return values from the function or failing task processes are ignored.
  No indication is provided whether a value was dropped due to falsy return value
  from the function or because of a failing process. If you need to separate
  failing processes from falsy return values, consider using `Exco.map_nolink/3`
  and filtering separately.

  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.filter_nolink(1..3, fn x -> x < 3 end)
      [ok: 1, ok: 2]

  """
  @spec filter_nolink(Enumerable.t, (any -> as_boolean(any)), keyword) :: [ok]
  def filter_nolink(enumerable, fun, opts \\ []) do
    run(:filter, enumerable, fun, opts)
  end
end
