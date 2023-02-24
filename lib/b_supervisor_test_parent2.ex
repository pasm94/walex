defmodule BSupervisorTestParent2 do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      {
        WalEx.Supervisor,
        configs()
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp configs do
    [
      hostname: "localhost",
      username: "postgres",
      password: "postgres",
      port: 5432,
      database: "nl_test",
      subscriptions: [:offers],
      publication: "events",
      modules: [NLInventoryManagement.Offers.OffersTableEventsListener22],
      name: __MODULE__
    ]
  end
end
