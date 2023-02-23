defmodule WalEx.Configs do
  use GenServer

  def start_link(opts) do
    IO.inspect(opts)
    configs = Keyword.get(opts, :configs)
    name = Keyword.get(configs, :name)
    name = String.to_atom("#{to_string(name)}_conf")
    GenServer.start_link(__MODULE__, configs, name: name)
  end

  def init(opts) do
    {:ok, opts}
  end

  def get_configs(name) do
    name = String.to_atom("#{to_string(name)}_conf")
    GenServer.call(name, :get_configs)
  end

  # Callbacks
  def handle_call(:get_configs, _from, actual_state) do
    {:reply, actual_state, actual_state}
  end
end
