defmodule ExcoTest do
  use ExUnit.Case
  doctest Exco

  test "map" do
    assert Exco.map([], &(&1 * &1)) == []
    assert Exco.map([1, 2, 3], &(&1 * &1)) == [1, 4, 9]

    assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: 2) == [1, 4, 9]
    assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: :auto) == [1, 4, 9]

    assert Exco.map([1, 2, 3], &(&1 * &1), linkage: :link) == [1, 4, 9]
    assert Exco.map([1, 2, 3], &(&1 * &1), linkage: :nolink) == [{:ok, 1}, {:ok, 4}, {:ok, 9}]
  end

  test "each" do
    assert Exco.each([], fn x -> x end) == :ok

    pid = self()

    l = [1, 2, 3]
    assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end) == :ok
    assert each_receive_loop([]) == l

    l = [1, 2, 3]
    assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end, max_concurrency: 2) == :ok
    assert each_receive_loop([]) == l

    l = [1, 2, 3]
    assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end, linkage: :nolink) == :ok
    assert each_receive_loop([]) == l
  end

  test "filter" do
    assert Exco.filter([1, 2, 3], &(&1 * 2 < 5)) == [1, 2]
    assert Exco.filter([1, 2, 3], &(&1 * 2 < 5), max_concurrency: 2) == [1, 2]
    assert Exco.filter([1, 2, 3], &(&1 * 2 < 5), linkage: :nolink) == [ok: 1, ok: 2]
  end

  defp each_receive_loop(result, counter \\ 1) do
    receive do
      {:value, x, total} when total == counter ->
        send(self(), :done)
        each_receive_loop([x | result], counter)

      {:value, x, _total} ->
        each_receive_loop([x | result], counter + 1)

      :done ->
        Enum.sort(result)

      other ->
        {:invalid_message, other}
    end
  end
end
