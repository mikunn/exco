defmodule ExcoTest do
  use ExUnit.Case
  doctest Exco

  test "map linked" do
    assert Exco.map([], &(&1 * &1)) == []
    assert Exco.map([1, 2, 3], &(&1 * &1)) == [1, 4, 9]
    assert Exco.map([1, 2, 3], &(&1 * &1), link: true) == [1, 4, 9]

    assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: 2) == [1, 4, 9]
    assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers) == [1, 4, 9]
    assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: :full) == [1, 4, 9]
  end

  test "map unlinked" do
    assert Exco.map([], &(&1 * &1), link: false) == []
    assert Exco.map([1, 2, 3], &(&1 * &1), link: false) == [ok: 1, ok: 4, ok: 9]

    assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: 2, link: false) == [ok: 1, ok: 4, ok: 9]
    assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers, link: false) == [ok: 1, ok: 4, ok: 9]
    assert Exco.map([1, 2, 3], &(&1 * &1), max_concurrency: :full, link: false) == [ok: 1, ok: 4, ok: 9]
  end

  test "stream_map linked" do
    stream = Exco.stream_map([], &(&1 * &1))
    assert stream?(stream)
    assert Enum.to_list(stream) == []

    assert Exco.stream_map([1, 2, 3], &(&1 * &1)) |> Enum.to_list == [1, 4, 9]

    stream = Exco.stream_map([1, 2, 3], &(&1 * &1), link: true)
    assert stream?(stream)
    assert Enum.to_list(stream) == [1, 4, 9]

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

  test "stream_map unlinked" do
    stream = Exco.stream_map([], &(&1 * &1), link: false)
    assert stream?(stream)
    assert Enum.to_list(stream) == []

    assert Exco.stream_map([1, 2, 3], &(&1 * &1), link: false) |> Enum.to_list == [ok: 1, ok: 4, ok: 9]

    stream = Exco.stream_map([1, 2, 3], &(&1 * &1), max_concurrency: 2, link: false)
    assert stream?(stream)
    assert Enum.to_list(stream) == [ok: 1, ok: 4, ok: 9]

    stream = Exco.stream_map([1, 2, 3], &(&1 * &1), max_concurrency: :schedulers, link: false)
    assert stream?(stream)
    assert Enum.to_list(stream) == [ok: 1, ok: 4, ok: 9]

    stream = Exco.stream_map([1, 2, 3], &(&1 * &1), max_concurrency: :full, link: false)
    assert stream?(stream)
    assert Enum.to_list(stream) == [ok: 1, ok: 4, ok: 9]
  end

  test "each linked" do
    assert Exco.each([], fn x -> x end) == :ok

    pid = self()

    l = [1, 2, 3]
    assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end) == :ok
    assert each_receive_loop([]) == l

    l = [1, 2, 3]
    assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end, max_concurrency: 2) == :ok
    assert each_receive_loop([]) == l
  end

  test "each unlinked" do
    assert Exco.each([], fn x -> x end) == :ok

    pid = self()

    l = [1, 2, 3]
    assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end, link: false) == :ok
    assert each_receive_loop([]) == l

    l = [1, 2, 3]

    assert Exco.each(l, fn x -> send(pid, {:value, x, length(l)}) end, max_concurrency: 2, link: false) ==
             :ok

    assert each_receive_loop([]) == l
  end

  test "filter linked" do
    assert Exco.filter([1, 2, 3], &(&1 * 2 < 5)) == [1, 2]
    assert Exco.filter([1, 2, 3], &(&1 * 2 < 5), max_concurrency: 2) == [1, 2]
  end

  test "filter unlinked" do
    assert Exco.filter([1, 2, 3], &(&1 * 2 < 5), link: false) == [1, 2]
    assert Exco.filter([1, 2, 3], &(&1 * 2 < 5), max_concurrency: 2, link: false) == [1, 2]
  end

  test "map linked: tasks run to completion when caller finishes" do
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

  test "map linked: tasks die when caller dies" do
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

  test "map linked with max_concurrency: tasks die when caller dies" do
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

  test "map linked: caller dies when a task dies" do
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

  test "each linked: tasks die when caller dies" do
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

  test "each linked: caller dies when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        Exco.each([1, 0, 2], fn _ ->
          Process.sleep(10)
          Process.exit(self(), :kill)
        end)
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    refute_receive :caller_alive
  end

  test "filter linked: tasks die when caller dies" do
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

  test "filter linked: caller dies when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        Exco.filter([1, 0, 2], fn _ ->
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

  test "map unlinked: tasks run to completion when caller finishes" do
    pid = self()

    spawn(fn ->
      Exco.map([1, 2, 3], fn x ->
        Process.sleep(50)
        send(pid, :task_alive)
        x
      end, link: false)

      send(pid, :result)
    end)

    Process.sleep(30)

    assert_receive :task_alive
    assert_receive :result
  end

  test "map unlinked: tasks run to completion when caller dies" do
    pid = self()

    caller =
      spawn(fn ->
        Exco.map([1, 2, 3], fn x ->
          Process.sleep(50)
          send(pid, :task_alive)
          x
        end, link: false)
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    assert_receive :task_alive
    assert_receive :task_alive
    assert_receive :task_alive
  end

  test "map unlinked: caller runs to completion when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        result =
          Exco.map([1, 0, 2], fn x ->
            Process.sleep(10)

            if x == 0 do
              Process.exit(self(), :kill)
            else
              x
            end
          end, link: false)

        send(pid, {:result, result})
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    assert_receive :caller_alive
    assert_receive {:result, [ok: 1, exit: :killed, ok: 2]}
  end

  test "stream_map unlinked: tasks run to completion when caller finishes" do
    pid = self()

    fun = fn x ->
      Process.sleep(50)
      send(pid, :task_alive)
      x
    end

    spawn(fn ->
      Exco.stream_map([1, 2, 3], fun, link: false)
      |> Enum.to_list

      send(pid, :result)
    end)

    Process.sleep(30)

    assert_receive :task_alive
    assert_receive :result
  end

  test "stream_map unlinked: tasks run to completion when caller dies" do
    pid = self()

    fun = fn x ->
      Process.sleep(50)
      send(pid, :task_alive)
      x
    end

    caller =
      spawn(fn ->
        Exco.stream_map([1, 2, 3], fun, link: false)
        |> Enum.to_list
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    assert_receive :task_alive
    assert_receive :task_alive
    assert_receive :task_alive
  end

  test "stream_map unlinked: caller runs to completion when a task dies" do
    pid = self()

    fun = fn x ->
      Process.sleep(10)

      if x == 0 do
        Process.exit(self(), :kill)
      else
        x
      end
    end

    spawn(fn ->
      spawn_link(fn ->
        result =
          Exco.stream_map([1, 0, 2], fun, link: false)
          |> Enum.to_list

        send(pid, {:result, result})
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    assert_receive :caller_alive
    assert_receive {:result, [ok: 1, exit: :killed, ok: 2]}
  end

  test "each unlinked: tasks run to completion when caller dies" do
    pid = self()

    caller =
      spawn(fn ->
        Exco.each([1, 2, 3], fn x ->
          Process.sleep(50)
          send(pid, :task_alive)
          x
        end, link: false)
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    assert_receive :task_alive
    assert_receive :task_alive
    assert_receive :task_alive
  end

  test "each unlinked: caller runs to completion when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        result =
          Exco.each([1, 0, 2], fn x ->
            Process.sleep(10)

            if x == 0 do
              Process.exit(self(), :kill)
            else
              x
            end
          end, link: false)

        send(pid, {:result, result})
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    assert_receive :caller_alive
    assert_receive {:result, :ok}
  end

  test "filter unlinked: tasks run to completion when caller dies" do
    pid = self()

    caller =
      spawn(fn ->
        Exco.filter([1, 2, 3], fn x ->
          Process.sleep(50)
          send(pid, :task_alive)
          x
        end, link: false)
      end)

    Process.sleep(30)
    Process.exit(caller, :kill)

    assert_receive :task_alive
    assert_receive :task_alive
    assert_receive :task_alive
  end

  test "filter unlinked: caller runs to completion when a task dies" do
    pid = self()

    spawn(fn ->
      spawn_link(fn ->
        result =
          Exco.filter([1, 0, 2], fn x ->
            Process.sleep(10)

            if x == 0 do
              Process.exit(self(), :kill)
            else
              x < 2
            end
          end, link: false)

        send(pid, {:result, result})
      end)

      Process.sleep(50)
      send(pid, :caller_alive)
    end)

    assert_receive :caller_alive
    assert_receive {:result, [1]}
  end

  defp stream?(enumerable) do
    match?(%Stream{}, enumerable)
  end
end

