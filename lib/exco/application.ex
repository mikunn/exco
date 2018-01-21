defmodule Exco.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Exco.TaskSupervisor, restart: :temporary, type: :supervisor}
    ]

    opts = [strategy: :one_for_one, name: Exco.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
