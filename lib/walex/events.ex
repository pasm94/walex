defmodule WalEx.Events do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def process(txn, server) do
    GenServer.call(__MODULE__, {:process, txn, server}, :infinity)
  end

  @impl true
  def init(%{}) do
    {:ok, %{}}
  end

  # def set_state(new_state) do
  #   GenServer.call(__MODULE__, {:set_state, new_state})
  # end

  # # Callbacks

  # def handle_call({:set_state, new_state}, _from, state) do
  #   new_state = [module: Keyword.get(state, :module) ++ Keyword.get(new_state, :module)]

  #   {:reply, new_state, new_state}
  # end

  @impl true
  def handle_call({:process, txn, server}, _from, state) do
    # get server modules and process transaction
    server
    |> WalEx.Configs.get_configs([:modules])
    |> process_events(txn)

    {:reply, :ok, state}
  end

  defp process_events([modules: modules], txn) when is_list(modules) do
    Enum.each(modules, fn module -> module.process(txn) end)
  end

  defp process_events([modules: module], txn), do: module.process(txn)

  defp process_events(nil, %{changes: [], commit_timestamp: _}), do: nil
end
