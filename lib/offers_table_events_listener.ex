defmodule NLInventoryManagement.Offers.OffersTableEventsListener do
  @moduledoc """
  Proccess events from offers table.
  """

  @behaviour WalEx.Event

  def process(_txn) do
    IO.puts("CHEGOU change do NL DEV")
    :ok
  end
end
