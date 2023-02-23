defmodule WalEx do
  @moduledoc """
  Documentation for `WalEx`.
  """
  def get_configs(name) do
    WalEx.Configs.get_configs(name)
  end
end
