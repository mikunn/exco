defmodule ExcoTest do
  use ExUnit.Case
  doctest Exco

  describe "map" do
    test "basic functionality" do
      assert Exco.map([], &(&1 * &1)) == []
      assert Exco.map([1, 2, 3], &(&1 * &1)) == [1, 4, 9]
      assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: 2) == [1, 4, 9]
      assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers) == [1, 4, 9]
      assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: :full) == [1, 4, 9]
    end

    test "tasks run to completion when caller finishes" do
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

    test "tasks die when caller dies" do
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

    test "caller dies when a task dies" do
      pid = self()

      spawn(fn ->
        spawn_link(fn ->
          Exco.map([1, 0, 2], fn _ ->
            Process.exit(self(), :kill)
          end)
        end)

        Process.sleep(50)
        send(pid, :caller_alive)
      end)

      refute_receive :caller_alive
    end

  end

  describe "map_nolink" do
    test "basic functionality" do
      assert Exco.map_nolink([], &(&1 * &1)) == []
      assert Exco.map_nolink([1, 2, 3], &(&1 * &1)) == [ok: 1, ok: 4, ok: 9]

      assert Exco.map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: 2) == [ok: 1, ok: 4, ok: 9]
      assert Exco.map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers) == [ok: 1, ok: 4, ok: 9]
      assert Exco.map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: :full) == [ok: 1, ok: 4, ok: 9]
    end

    test "caller runs to completion when a task dies" do
      pid = self()

      spawn(fn ->
        spawn_link(fn ->
          result =
            Exco.map_nolink([1, 0, 2], fn x ->
              if x == 0 do
                Process.sleep(10)
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

    test "tasks run to completion when caller finishes" do
      pid = self()

      spawn(fn ->
        Exco.map_nolink([1, 2, 3], fn x ->
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

    test "tasks run to completion when caller dies" do
      pid = self()

      caller =
        spawn(fn ->
          Exco.map_nolink([1, 2, 3], fn x ->
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
  end

  describe "stream_map" do
    test "basic functionality" do
      stream = Exco.stream_map([], &(&1 * &1))
      assert stream?(stream)
      assert Enum.to_list(stream) == []

      assert Exco.stream_map([1, 2, 3], &(&1 * &1)) |> Enum.to_list == [1, 4, 9]

      stream = Exco.stream_map([1, 2, 3], &(&1 * &1), max_concurrency: 2)
      assert stream?(stream)
      assert Enum.to_list(stream) == [1, 4, 9]

      stream = Exco.stream_map([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers)
      assert stream?(stream)
      assert Enum.to_list(stream) == [1, 4, 9]

      stream = Exco.stream_map([1, 2, 3], &(&1 * &1), max_concurrency: :full)
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
        Exco.stream_map([1, 2, 3], fun)
        |> Enum.to_list

        send(pid, :result)
      end)

      Process.sleep(30)

      assert_receive :task_alive
      assert_receive :result
    end

    test "stream_map: tasks die when caller dies" do
      pid = self()

      fun = fn x ->
        Process.sleep(50)
        send(pid, :task_alive)
        x
      end

      caller =
        spawn(fn ->
          Exco.stream_map([1, 2, 3], fun)
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
          Exco.stream_map([1, 0, 2], fun)
          |> Enum.to_list
        end)

        Process.sleep(50)
        send(pid, :caller_alive)
      end)

      refute_receive :caller_alive
    end

  end

  describe "stream_map_nolink" do
    test "basic functionality" do
      stream = Exco.stream_map_nolink([], &(&1 * &1))
      assert stream?(stream)
      assert Enum.to_list(stream) == []

      assert Exco.stream_map_nolink([1, 2, 3], &(&1 * &1)) |> Enum.to_list == [ok: 1, ok: 4, ok: 9]

      stream = Exco.stream_map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: 2)
      assert stream?(stream)
      assert Enum.to_list(stream) == [ok: 1, ok: 4, ok: 9]

      stream = Exco.stream_map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers)
      assert stream?(stream)
      assert Enum.to_list(stream) == [ok: 1, ok: 4, ok: 9]

      stream = Exco.stream_map_nolink([1, 2, 3], &(&1 * &1), max_concurrency: :full)
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
        Exco.stream_map_nolink([1, 2, 3], fun)
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
          Exco.stream_map_nolink([1, 2, 3], fun)
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
            Exco.stream_map_nolink([1, 0, 2], fun)
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

  describe "each" do
    test "basic functionality" do
      assert Exco.each([], fn x -> x end) == :ok

      pid = self()

      l = [1, 2, 3]
      assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end) == :ok
      assert each_receive_loop([]) == l

      l = [1, 2, 3]
      assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end, max_concurrency: 2) == :ok
      assert each_receive_loop([]) == l
    end

    test "tasks die when caller dies" do
      pid = self()

      caller =
        spawn(fn ->
          Exco.each([1, 2, 3], fn x ->
            Process.sleep(50)
            send(pid, :task_alive)
            x
          end)
        end)

      Process.sleep(30)
      Process.exit(caller, :kill)

      refute_receive :task_alive
    end

    test "caller dies when a task dies" do
      pid = self()

      spawn(fn ->
        spawn_link(fn ->
          Exco.each([1, 0, 2], fn _ ->
            Process.exit(self(), :kill)
          end)
        end)

        Process.sleep(50)
        send(pid, :caller_alive)
      end)

      refute_receive :caller_alive
    end

  end

  describe "each_nolink" do
    test "basic functionality" do
      assert Exco.each_nolink([], fn x -> x end) == :ok

      pid = self()

      l = [1, 2, 3]
      assert Exco.each_nolink(l, fn x -> send(pid, {:value, x, length(l)}) end) == :ok
      assert each_receive_loop([]) == l

      l = [1, 2, 3]

      assert Exco.each_nolink(l, fn x -> send(pid, {:value, x, length(l)}) end, max_concurrency: 2) ==
               :ok

      assert each_receive_loop([]) == l
    end

    test "tasks run to completion when caller dies" do
      pid = self()

      caller =
        spawn(fn ->
          Exco.each_nolink([1, 2, 3], fn x ->
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

    test "caller runs to completion when a task dies" do
      pid = self()

      spawn(fn ->
        spawn_link(fn ->
          result =
            Exco.each_nolink([1, 0, 2], fn x ->
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
  end

  describe "filter" do
    test "basic functionality" do
      assert Exco.filter([1, 2, 3], &(&1 * 2 < 5)) == [1, 2]
      assert Exco.filter([1, 2, 3], &(&1 * 2 < 5), max_concurrency: 2) == [1, 2]
    end

    test "caller dies when a task dies" do
      pid = self()

      spawn(fn ->
        spawn_link(fn ->
          Exco.filter([1, 0, 2], fn _ ->
            Process.exit(self(), :kill)
          end)
        end)

        Process.sleep(50)
        send(pid, :caller_alive)
      end)

      refute_receive :caller_alive
    end

    test "tasks die when caller dies" do
      pid = self()

      caller =
        spawn(fn ->
          Exco.filter([1, 2, 3], fn x ->
            Process.sleep(50)
            send(pid, :task_alive)
            x
          end)
        end)

      Process.sleep(30)
      Process.exit(caller, :kill)

      refute_receive :task_alive
    end
  end

  describe "filter_nolink" do
    test "basic functionality" do
      assert Exco.filter_nolink([1, 2, 3], &(&1 * 2 < 5)) == [1, 2]
      assert Exco.filter_nolink([1, 2, 3], &(&1 * 2 < 5), max_concurrency: 2) == [1, 2]
    end

    test "tasks run to completion when caller dies" do
      pid = self()

      caller =
        spawn(fn ->
          Exco.filter_nolink([1, 2, 3], fn x ->
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

    test "caller runs to completion when a task dies" do
      pid = self()

      spawn(fn ->
        spawn_link(fn ->
          result =
            Exco.filter_nolink([1, 0, 2], fn x ->
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
      assert_receive {:result, [1]}
    end
  end

  defp stream?(enumerable) do
    match?(%Stream{}, enumerable)
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

