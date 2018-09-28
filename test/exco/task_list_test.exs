defmodule Exco.TaskListTest do
  use ExUnit.Case, async: true
  doctest Exco.TaskList

  describe "await" do
    test "accepts the return value from async()" do
      results =
        Exco.TaskList.async([fn -> 1 end])
        |> Exco.TaskList.await()

      assert results == [1]
    end

    test "accepts a list of tasks" do
      task = Task.async(fn -> 1 end)
      assert Exco.TaskList.await([task]) == [1]
    end
  end

  describe "async/await" do
    test "basic functionality" do
      results =
        1..3
        |> Enum.map(&(fn -> &1 end))
        |> Exco.TaskList.async()
        |> Exco.TaskList.await()

      assert results == [1, 2, 3]
    end

    test "result retrieval is deferred until await is called" do
      tasklist =
        ["f", "o", "o"]
        |> Enum.map(&(fn -> &1 end))
        |> Exco.TaskList.async()

      str = "bar"

      str =
        tasklist
        |> Exco.TaskList.await()
        |> Enum.join("")
        |> Kernel.<>(str)

      assert str == "foobar"
    end

    test "caller and task exit as task takes longer than timeout" do
      Process.flag(:trap_exit, true)
      main = self()

      funs =
        for x <- [1, 10, 11] do
          fn ->
            Process.sleep(x);
            send(main, {:alive, x})
          end
        end

      caller = spawn_link(fn ->
        funs
        |> Exco.TaskList.async
        |> Exco.TaskList.await(2)
      end)

      assert_receive {:EXIT, ^caller, {:timeout, _, _}}
      assert_receive {:alive, 1}
      refute_receive {:alive, 10}
      refute_receive {:alive, 11}
    end

    test "task stays alive after timeout when trapping exits" do
      Process.flag(:trap_exit, true)
      main = self()

      funs =
        for x <- [1, 10, 11] do
          fn ->
            Process.flag(:trap_exit, true)
            Process.sleep(x);
            send(main, {:alive, x})
          end
        end

      caller = spawn_link(fn ->
        funs
        |> Exco.TaskList.async
        |> Exco.TaskList.await(2)
      end)

      assert_receive {:EXIT, ^caller, {:timeout, _, _}}
      assert_receive {:alive, 1}
      assert_receive {:alive, 10}
      assert_receive {:alive, 11}
    end

    test "each task finishes before timeout" do
      funs =
        for x <- 1..3 do
          fn -> Process.sleep(x*10); x end
        end

      results =
        funs
        |> Exco.TaskList.async
        |> Exco.TaskList.await(40)

      assert results == [1, 2, 3]
    end

    @tag capture_log: true
    test "error in task kills the caller" do
      Process.flag(:trap_exit, true)

      caller = spawn_link(fn ->
        funs =
          for x <- 2..0 do
            fn -> 2/x end
          end

        funs
        |> Exco.TaskList.async
        |> Exco.TaskList.await
      end)

      assert_receive {:EXIT, ^caller, {:badarith, _}}
    end

    @tag capture_log: true
    test "error in task kills the caller even if it's trapping exits" do
      Process.flag(:trap_exit, true)

      caller = spawn_link(fn ->
        Process.flag(:trap_exit, true)
        funs =
          for x <- 2..0 do
            fn -> 2/x end
          end

        funs
        |> Exco.TaskList.async
        |> Exco.TaskList.await
      end)

      assert_receive {:EXIT, ^caller, {{:badarith, _}, _, _}}
    end
  end
end
