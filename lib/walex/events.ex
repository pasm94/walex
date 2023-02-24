defmodule WalEx.Events do
  use GenServer

  def start_link(process_event) do
    GenServer.start_link(__MODULE__, process_event, name: __MODULE__)
  end

  def process(txn) do
    GenServer.call(__MODULE__, {:process, txn}, :infinity)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def set_state(new_state) do
    GenServer.call(__MODULE__, {:set_state, new_state})
  end

  # Callbacks

  def handle_call({:set_state, new_state}, _from, state) do
    new_state = [module: Keyword.get(state, :module) ++ Keyword.get(new_state, :module)]

    {:reply, new_state, new_state}
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
