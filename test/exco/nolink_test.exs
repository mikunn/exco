defmodule Exco.NolinkTest do
  use ExUnit.Case
  doctest Exco.Nolink

  test "map" do
    assert Exco.Nolink.map([], &(&1 * &1)) == []
    assert Exco.Nolink.map([1, 2, 3], &(&1 * &1)) == [ok: 1, ok: 4, ok: 9]

    assert Exco.Nolink.map([1, 2, 3], &(&1 * &1), max_concurrency: 2) == [ok: 1, ok: 4, ok: 9]
    assert Exco.Nolink.map([1, 2, 3], &(&1 * &1), max_concurrency: :auto) == [ok: 1, ok: 4, ok: 9]
  end

  test "each" do
    assert Exco.each([], fn x -> x end) == :ok

    pid = self()

    l = [1, 2, 3]
    assert Exco.Nolink.each(l, fn x -> send(pid, {:value, x, length(l)}) end) == :ok
    assert each_receive_loop([]) == l

    l = [1, 2, 3]

    assert Exco.Nolink.each(l, fn x -> send(pid, {:value, x, length(l)}) end, max_concurrency: 2) ==
             :ok

    assert each_receive_loop([]) == l
  end

  test "filter" do
    assert Exco.Nolink.filter([1, 2, 3], &(&1 * 2 < 5)) == [ok: 1, ok: 2]
    assert Exco.Nolink.filter([1, 2, 3], &(&1 * 2 < 5), max_concurrency: 2) == [ok: 1, ok: 2]
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

  test "map: tasks run to completion when caller finishes" do
    pid = self()

    spawn(fn ->
      Exco.Nolink.map([1, 2, 3], fn x ->
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

  test "map: tasks run to completion when caller dies" do
    pid = self()

    caller =
      spawn(fn ->
        Exco.Nolink.map([1, 2, 3], fn x ->
          Process.sleep(50)
          send(pid, :task_alive)
          x
        end)
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    assert_receive :task_alive
    assert_receive :task_alive
    assert_receive :task_alive
  end

  test "map: caller runs to completion when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        result =
          Exco.Nolink.map([1, 0, 2], fn x ->
            Process.sleep(10)

            if x == 0 do
              Process.exit(self(), :kill)
            else
              x
            end
          end)

        send(pid, {:result, result})
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    assert_receive :caller_alive
    assert_receive {:result, [ok: 1, exit: :killed, ok: 2]}
  end

  test "each: tasks run to completion when caller dies" do
    pid = self()

    caller =
      spawn(fn ->
        Exco.Nolink.each([1, 2, 3], fn x ->
          Process.sleep(50)
          send(pid, :task_alive)
          x
        end)
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    assert_receive :task_alive
    assert_receive :task_alive
    assert_receive :task_alive
  end

  test "each: caller runs to completion when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        result =
          Exco.Nolink.each([1, 0, 2], fn x ->
            Process.sleep(10)

            if x == 0 do
              Process.exit(self(), :kill)
            else
              x
            end
          end)

        send(pid, {:result, result})
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    assert_receive :caller_alive
    assert_receive {:result, :ok}
  end

  test "filter: tasks run to completion when caller dies" do
    pid = self()

    caller =
      spawn(fn ->
        Exco.Nolink.filter([1, 2, 3], fn x ->
          Process.sleep(50)
          send(pid, :task_alive)
          x
        end)
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    assert_receive :task_alive
    assert_receive :task_alive
    assert_receive :task_alive
  end

  test "filter: caller runs to completion when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        result =
          Exco.Nolink.filter([1, 0, 2], fn x ->
            Process.sleep(10)

            if x == 0 do
              Process.exit(self(), :kill)
            else
              x < 2
            end
          end)

        send(pid, {:result, result})
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    assert_receive :caller_alive
    assert_receive {:result, [ok: 1]}
  end
end
