defmodule NLInventoryManagement.Offers.OffersTableEventsListener22 do
  @moduledoc """
  Proccess events from offers table.
  """

  @behaviour WalEx.Event

  def process(_txn) do
    IO.puts("CHEGOU change do NL test")
    :ok
  end
end
