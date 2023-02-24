# This file steals liberally from https://github.com/chasers/postgrex_replication_demo/blob/main/lib/replication.ex
# which in turn draws on https://hexdocs.pm/postgrex/Postgrex.ReplicationConnection.html#module-logical-replication

defmodule WalEx.ReplicationServer do
  use Postgrex.ReplicationConnection

  alias WalEx.Postgres.Decoder
  alias WalEx.ReplicationPublisher

  @publication "events"

  def start_link(opts) do
    # Automatically reconnect if we lose connection.
    extra_opts = [auto_reconnect: true]

    name = opts[:configs][:name]

    opts = opts[:configs]

    Postgrex.ReplicationConnection.start_link(
      __MODULE__,
      [other: name],
      extra_opts ++ opts ++ [name: {:via, Registry, {:walex_registry, {__MODULE__, name}}}]
    )
  end

  @impl true
  def init(data) do
    if is_nil(Process.whereis(ReplicationPublisher)) do
      {:ok, _pid} = ReplicationPublisher.start_link([])
    end

    {:ok, %{step: :disconnected, data: data}}
  end

  @impl true
  def handle_connect(state) do
    temp_slot = "walex_temp_slot_" <> Integer.to_string(:rand.uniform(9_999))

    query = "CREATE_REPLICATION_SLOT #{temp_slot} TEMPORARY LOGICAL pgoutput NOEXPORT_SNAPSHOT;"

    {:query, query, %{state | step: :create_slot}}
  end

  @impl true
  def handle_result([%Postgrex.Result{rows: rows} | _results], %{step: :create_slot} = state) do
    slot_name = rows |> hd |> hd

    query =
      "START_REPLICATION SLOT #{slot_name} LOGICAL 0/0 (proto_version '1', publication_names '#{@publication}')"

    {:stream, query, [], %{state | step: :streaming}}
  end

  @impl true
  # https://www.postgresql.org/docs/14/protocol-replication.html
  def handle_data(<<?w, wal_start::64, wal_end::64, clock::64, rest::binary>>, state) do
    IO.inspect(state)

    rest
    |> Decoder.decode_message()
    |> ReplicationPublisher.process_message()

    {:noreply, state}
  end

  def handle_data(<<?k, wal_end::64, _clock::64, reply>>, state) do
    messages =
      case reply do
        1 -> [<<?r, wal_end + 1::64, wal_end + 1::64, wal_end + 1::64, current_time()::64, 0>>]
        0 -> []
      end

    {:noreply, messages, state}
  end

  @epoch DateTime.to_unix(~U[2000-01-01 00:00:00Z], :microsecond)
  defp current_time(), do: System.os_time(:microsecond) - @epoch
end
