defmodule Exco.StreamTest do
  use ExUnit.Case, async: true
  doctest Exco.Stream

  describe "map" do
    test "basic functionality" do
      stream = Exco.Stream.map([], &(&1 * &1))
      assert stream?(stream)
      assert Enum.to_list(stream) == []

      assert Exco.Stream.map([1, 2, 3], &(&1 * &1)) |> Enum.to_list == [1, 4, 9]

      stream = Exco.Stream.map([1, 2, 3], &(&1 * &1), max_concurrency: 2)
      assert stream?(stream)
      assert Enum.to_list(stream) == [1, 4, 9]

      stream = Exco.Stream.map([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers)
      assert stream?(stream)
      assert Enum.to_list(stream) == [1, 4, 9]

      stream = Exco.Stream.map([1, 2, 3], &(&1 * &1), max_concurrency: :full)
      assert stream?(stream)
      assert Enum.to_list(stream) == [1, 4, 9]
    end

    test "tasks run to completion when caller finishes" do
      pid = self()

      fun = fn x ->
        Process.sleep(50)
        send(pid, :task_alive)
        x
      end

      spawn(fn ->
        Exco.Stream.map([1, 2, 3], fun)
        |> Enum.to_list

        send(pid, :result)
      end)

      Process.sleep(30)

      assert_receive :task_alive
      assert_receive :result
    end

    test "map: tasks die when caller dies" do
      pid = self()

      fun = fn x ->
        Process.sleep(50)
        send(pid, :task_alive)
        x
      end

      caller =
        spawn(fn ->
          Exco.Stream.map([1, 2, 3], fun)
          |> Enum.to_list
        end)

      Process.sleep(30)
      Process.exit(caller, :kill)

      refute_receive :task_alive
    end

    test "caller dies when a task dies" do
      pid = self()

      fun = fn _ ->
        Process.exit(self(), :kill)
      end

      spawn(fn ->
        spawn_link(fn ->
          Exco.Stream.map([1, 0, 2], fun)
          |> Enum.to_list
        end)

        Process.sleep(50)
        send(pid, :caller_alive)
      end)

      refute_receive :caller_alive
    end

  end

  describe "map_nolink" do
    test "basic functionality" do
      stream = Exco.Stream.map_nolink([], &(&1 * &1))
      assert stream?(stream)
      assert Enum.to_list(stream) == []

      assert Exco.Stream.map_nolink([1, 2, 3], &(&1 * &1)) |> Enum.to_list == [ok: 1, ok: 4, ok: 9]

      stream = Exco.Stream.map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: 2)
      assert stream?(stream)
      assert Enum.to_list(stream) == [ok: 1, ok: 4, ok: 9]

      stream = Exco.Stream.map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers)
      assert stream?(stream)
      assert Enum.to_list(stream) == [ok: 1, ok: 4, ok: 9]

      stream = Exco.Stream.map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: :full)
      assert stream?(stream)
      assert Enum.to_list(stream) == [ok: 1, ok: 4, ok: 9]
    end

    test "tasks run to completion when caller finishes" do
      pid = self()

      fun = fn x ->
        Process.sleep(50)
        send(pid, :task_alive)
        x
      end

      spawn(fn ->
        Exco.Stream.map_nolink([1, 2, 3], fun)
        |> Enum.to_list

        send(pid, :result)
      end)

      Process.sleep(30)

      assert_receive :task_alive
      assert_receive :result
    end

    test "tasks run to completion when caller dies" do
      pid = self()

      fun = fn x ->
        Process.sleep(50)
        send(pid, :task_alive)
        x
      end

      caller =
        spawn(fn ->
          Exco.Stream.map_nolink([1, 2, 3], fun)
          |> Enum.to_list
        end)

      Process.sleep(30)
      Process.exit(caller, :kill)

      assert_receive :task_alive
      assert_receive :task_alive
      assert_receive :task_alive
    end

    test "caller runs to completion when a task dies" do
      pid = self()

      fun = fn x ->
        if x == 0 do
          Process.sleep(10)
          Process.exit(self(), :kill)
        else
          x
        end
      end

      spawn(fn ->
        spawn_link(fn ->
          result =
            Exco.Stream.map_nolink([1, 0, 2], fun)
            |> Enum.to_list

          send(pid, {:result, result})
        end)

        Process.sleep(50)
        send(pid, :caller_alive)
      end)

      assert_receive :caller_alive
      assert_receive {:result, [ok: 1, exit: :killed, ok: 2]}
    end
  end

  defp stream?(enumerable) do
    match?(%Stream{}, enumerable)
  end
end
