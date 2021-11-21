defmodule Mix.Tasks.Relaxir.LocalDeploy do
  use Mix.Task
  import System, only: [cmd: 2, cmd: 3]

  @shortdoc "Deploy to the server from local install"
  def run([host]) do
    :ssh.start()
    {:ok, conn} = :ssh.connect(to_charlist(host), 22, silently_accept_hosts: true)

    [
      "mix deps.get --only prod",
      "mix compile",
      "mix assets.deploy",
      "mix release --overwrite",
      "tar -zcf relaxir.tar.gz _build/prod/rel/relaxir/",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null relaxir.tar.gz #{host}:relaxir.tar.gz"
    ]
    |> Enum.each(fn command ->
      IO.puts(">> #{command}")
      [command | args] = String.split(command, " ")
      cmd(command, args, env: [{"MIX_ENV", "prod"}])
    end)

    conn
    |> ssh(host, "tar -zxf relaxir.tar.gz")
    |> ssh(host, "sudo rsync -av --chown=relaxir:relaxir _build/prod/rel/relaxir/ /home/relaxir/relaxir/")
    |> ssh(
      host,
      "sudo -u relaxir bash -c 'cd /home/relaxir && source secrets.source && ./relaxir/bin/relaxir eval Relaxir.Release.migrate'"
    )
    |> ssh(host, "sudo systemctl restart relaxir")
    |> ssh(host, "sudo rsync -av --delete --chown=relaxir:relaxir _build/prod/rel/relaxir/ /home/relaxir/relaxir/")

    cmd("rm", ["relaxir.tar.gz"])
  end

  defp ssh(conn, host, command) do
    IO.puts("#{host} >> #{command}")
    {:ok, chan} = :ssh_connection.session_channel(conn, :infinity)
    :success = :ssh_connection.exec(conn, chan, command, :infinity)
    receive_ssh(conn)
    conn
  end

  defp receive_ssh(conn) do
    receive do
      {:ssh_cm, ^conn, {:exit_status, _, 0}} ->
        "SSH command failed"

      {:ssh_cm, ^conn, {:data, _, _, data}} ->
        IO.write(data)
        receive_ssh(conn)
    end
  end
end
