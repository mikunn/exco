defmodule ExcoLinkageTest do
  use ExUnit.Case
  doctest Exco

  test "linked map: tasks run to completion when caller finishes" do
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

  test "linked map: tasks die when caller dies" do
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

  test "linked map with max_concurrency: tasks die when caller dies" do
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

  test "linked map: caller dies when a task dies" do
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
end
