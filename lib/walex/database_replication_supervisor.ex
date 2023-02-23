defmodule WalEx.DatabaseReplicationSupervisor do
  use Supervisor

  alias WalEx.ReplicationServer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    children = [
      {
        ReplicationServer,
        configs: Keyword.get(opts, :configs), name: {:via, ReplicationServer, __MODULE__}
      }
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
