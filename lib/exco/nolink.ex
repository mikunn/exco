defmodule Exco.Nolink do
  @moduledoc ~S"""

  Concurrent versions of some of the `Enum` functions
  spawning the tasks without linking them to the caller.

  The caller is not affected by a terminated task and vice versa.
  Here's an example of a child that gets terminated by an error:

  ```elixir
  Exco.Nolink.map(0..2, fn x -> 1/x end)                                                
  [
    exit: {:badarith,
     [
       ...
     ]},
    ok: 1.0,
    ok: 0.5
  ]
  ```

  Since the expression `1/x` evaluates to `1/0` in the first task,
  the result has a tuple `{:exit, reason}` as the first item.

  Notice that `Exco.map/3` returns a list of the values,
  while `Exco.Nolink.map/3` returns a list consisting of either
  `{:ok, value}` or `{:exit, reason}` tuples.

  If the caller terminates, the tasks already spawned run to
  completion unaffected. Notice, however, that the caller is
  then not available to collect the results in case of i.e.
  `map` or `filter`.

  ## Options

  * `max_concurrency`: the maximum number of items to run concurrently.
    By default, this number equals to the return value of
    `System.schedulers_online/0`.
  """

  @doc ~S"""
  Concurrent version of `Enum.map/2`.

  The applied function runs in a new process for each item.
  These processes *are not* linked to the caller.

  The return value is a list consisting of either
  `{:ok, value}` or `{:error, reason}` tuples.
  The ordering is retained.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.Nolink.map(1..3, fn x -> x*2 end)
      [ok: 2, ok: 4, ok: 6]

  """
  def map(enumerable, fun, opts \\ []) do
    opts = Keyword.put(opts, :link, false)
    Exco.map(enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.each/2`.

  The applied function runs in a new process for each item.
  These processes *are not* linked to the caller.

  Returns `:ok`.

  See the [options](#module-options).

  ## Examples

      Exco.Nolink.each(1..3, fn x -> IO.puts x*2 end)
      2 
      4 
      6
      #=> :ok

  """
  def each(enumerable, fun, opts \\ []) do
    opts = Keyword.put(opts, :link, false)
    Exco.each(enumerable, fun, opts)
  end

  @doc ~S"""
  Concurrent version of `Enum.filter/2`.

  The applied function runs in a new process for each item.
  These processes *are not* linked to the caller.

  The return value is a list consisting of `{:ok, value}` tuples.
  The `value` in each tuple represents a value in the original
  enumerable for which the applied function returns a truthy value.
  The ordering is retained.

  Values for which the process terminated are left out from
  the result. Otherwise the original value for which the process
  failed should be included in the result making the result list
  quite messy.

  See the [options](#module-options).

  ## Examples:

      iex(1)> Exco.Nolink.filter(1..3, fn x -> x < 3 end)
      [ok: 1, ok: 2]

  """
  def filter(enumerable, fun, opts \\ []) do
    opts = Keyword.put(opts, :link, false)
    Exco.filter(enumerable, fun, opts)
  end
end
