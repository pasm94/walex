defmodule WalEx.Configs do
  use Agent

  def start_link(opts) do
    configs = Keyword.get(opts, :configs)
    name = Keyword.get(opts, :name)

    Agent.start_link(fn -> configs end, name: name)
  end

  def value(name) do
    Agent.get({:via, Registry, {:walex_registry, {__MODULE__, name}}}, & &1)
  end
end
