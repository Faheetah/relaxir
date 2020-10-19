defmodule Mix.Tasks.Relaxir.Deploy do
  use Mix.Task

  @shortdoc "Deploy to the server"
  def run([host]) do
    project = Relaxir.MixProject.project()
    version = project[:version]

    download_url = "#{project[:url]}/releases/download/#{version}/#{project[:app]}-ubuntu-20.04.tar.gz"

    :ssh.start()
    {:ok, conn} = :ssh.connect(to_charlist(host), 22, silently_accept_hosts: true)

    conn
    |> ssh("wget --progress=bar:force -O relaxir.tar.gz #{download_url}")
    |> ssh("tar -zvxf relaxir.tar.gz")
    |> ssh("sudo rsync -av --chown=relaxir:relaxir relaxir/ /home/relaxir/relaxir/")
    |> ssh("sudo -u relaxir bash -c 'cd /home/relaxir && source secrets.source && ./relaxir/bin/relaxir eval Relaxir.Release.migrate'")
    |> ssh("sudo systemctl restart relaxir")
    |> ssh("sudo rsync -av --delete --chown=relaxir:relaxir relaxir/ /home/relaxir/relaxir/")
  end

  defp ssh(conn, command) do
    IO.puts(">> #{command}")
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
