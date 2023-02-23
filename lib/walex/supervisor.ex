defmodule WalEx.Supervisor do
  use Supervisor

  alias WalEx.Configs, as: WalExConfigs
  alias WalEx.DatabaseReplicationSupervisor
  alias WalEx.Events

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name)

    Supervisor.start_link(__MODULE__, configs: opts, name: name)
  end

  # Supervisor trees
  # ----------------
  # 1)
  # WalEx.Supervisor
  # - WalEx.DatabaseReplicationSupervisor
  #   - WalEx.ReplicationServer
  #     - WalEx.ReplicationPublisher

  # 2)
  # WalEx.Supervisor
  # - WalEx.Events

  @impl true
  def init(opts) do
    configs = Keyword.get(opts, :configs)

    children = [
      {
        WalExConfigs,
        configs: configs, name: {:via, WalExConfigs, __MODULE__}
      },
      {
        DatabaseReplicationSupervisor,
        configs: get_configs(DatabaseReplicationSupervisor, configs),
        name: {:via, DatabaseReplicationSupervisor, __MODULE__}
      },
      {
        Events,
        configs: get_configs(Events, configs), name: {:via, Events, __MODULE__}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_configs(DatabaseReplicationSupervisor, configs) do
    db_configs_from_url =
      configs
      |> Keyword.get(:url, "")
      |> parse_url()

    [
      hostname: Keyword.get(configs, :hostname, db_configs_from_url[:hostname]),
      username: Keyword.get(configs, :username, db_configs_from_url[:username]),
      password: Keyword.get(configs, :password, db_configs_from_url[:password]),
      port: Keyword.get(configs, :port, db_configs_from_url[:port]),
      database: Keyword.get(configs, :database, db_configs_from_url[:database]),
      subscriptions: Keyword.get(configs, :subscriptions),
      publication: Keyword.get(configs, :publication),
      name: Keyword.get(configs, :name)
    ]
  end

  defp get_configs(Events, configs) do
    [
      module: configs[:modules],
      name: configs[:name]
    ]
  end

  defp parse_url(""), do: []

  defp parse_url(url) when is_binary(url) do
    info = URI.parse(url)

    if is_nil(info.host), do: raise("host is not present")

    if is_nil(info.path) or not (info.path =~ ~r"^/([^/])+$"),
      do: raise("path should be a database name")

    destructure [username, password], info.userinfo && String.split(info.userinfo, ":")
    "/" <> database = info.path

    url_opts = [
      username: username,
      password: password,
      database: database,
      port: info.port
    ]

    url_opts = put_hostname_if_present(url_opts, info.host)

    for {k, v} <- url_opts,
        not is_nil(v),
        do: {k, if(is_binary(v), do: URI.decode(v), else: v)}
  end

  defp put_hostname_if_present(keyword, ""), do: keyword

  defp put_hostname_if_present(keyword, hostname) when is_binary(hostname) do
    Keyword.put(keyword, :hostname, hostname)
  end
end
