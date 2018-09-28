defmodule Exco.TaskList do

  @moduledoc ~S"""
  Functions to run multiple functions concurrently.

  """

  defstruct tasks: []

  @type tl :: %__MODULE__ {
    tasks: [Task.t()]
  }

  @doc ~S"""
  Start running multiple functions concurrently.

  This is similar to `Task.async/1`, but takes a list
  of functions instead of a single function. You must call
  `Exco.TaskList.await/2` with the return value of this function
  to collect the results.

  Each function is run in its own task linked to the caller.

  ## Examples:

      iex> funs = for x <- 1..3, do: fn -> x*2 end
      iex> task_list = Exco.TaskList.async(funs)
      iex> Exco.TaskList.await(task_list)
      [2, 4, 6]

  """
  @spec async([(() -> any)]) :: tl
  def async(funs) do
    tasks =
      funs
      |> Enum.map(&Task.async/1)

    %Exco.TaskList{tasks: tasks}
  end

  @doc ~S"""
  Awaits a reply from each task process and returns them.

  This function is similar to `Task.await/2`, but accepts either
  a `Exco.TaskList` struct returned by `Exco.TaskList.async/1` or
  a list of tasks.

  Just like with `Task.await/2`, you can specify a `timeout` in
  milliseconds which defaults to `5000`. If the timeout is exceeded
  by any of the tasks (functions), the caller and all tasks that are
  not finished and are not trapping exits will exit.

  """
  @spec await([tl] | [Task.t], timeout) :: [term] | no_return
  def await(task_list, timeout \\ 5000)
  def await(%Exco.TaskList{tasks: tasks}, timeout), do: await(tasks, timeout)
  def await(tasks, timeout) do
    for {task, response} <- Task.yield_many(tasks, timeout) do
      case response do
        {:ok, value} -> value
        {:exit, reason} ->
          exit({reason, task, {__MODULE__, :await, [tasks, timeout]}})
        nil ->
          exit({:timeout, task, {__MODULE__, :await, [tasks, timeout]}})
      end
    end
  end
end

