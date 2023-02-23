defmodule WalEx.Events do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # DEIXAR POR ÚLTIMO POR CAUSA DAS CALLBACKS
  def process(txn) do
    GenServer.call(__MODULE__, {:process, txn}, :infinity)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:process, txn}, _from, state) do
    process_events(state, txn)
    {:reply, :ok, state}
  end

  defp process_events([module: modules], txn) when is_list(modules) do
    Enum.each(modules, fn module -> apply(module, :process, [txn]) end)
  end

  defp process_events([module: module], txn), do: apply(module, :process, [txn])

  defp process_events(nil, %{changes: [], commit_timestamp: _}), do: nil
end
