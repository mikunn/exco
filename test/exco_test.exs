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

  test "map: tasks run to completion when caller finishes" do
    pid = self()

    spawn(fn ->
      Exco.map([1, 2, 3], fn x ->
        Process.sleep(50)
        send(pid, :task_alive)
        x
      end)

      send(pid, :result)
    end)

    Process.sleep(30)

    assert_receive :task_alive
    assert_receive :result
  end

  test "map: tasks die when caller dies" do
    pid = self()

    caller =
      spawn(fn ->
        Exco.map([1, 2, 3], fn x ->
          Process.sleep(50)
          send(pid, :task_alive)
          x
        end)
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    refute_receive :task_alive
  end

  test "map with max_concurrency: tasks die when caller dies" do
    pid = self()

    fun = fn x ->
      Process.sleep(50)
      send(pid, :task_alive)
      x
    end

    caller =
      spawn(fn ->
        Exco.map(
          [1, 2, 3],
          fun,
          max_concurrency: 2
        )
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    refute_receive :task_alive
  end

  test "map: caller dies when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        Exco.map([1, 0, 2], fn _ ->
          Process.sleep(10)
          Process.exit(self(), :kill)
        end)
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    refute_receive :caller_alive
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
