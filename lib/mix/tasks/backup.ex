defmodule Mix.Tasks.Relaxir.Backup do
  use Mix.Task

  @shortdoc "Take a backup from the server"
  def run([host, path]) do
    :ssh.start()
    {:ok, conn} = :ssh.connect(to_charlist(host), 22, silently_accept_hosts: true)

    {_, data} = ssh(conn, "sudo -u relaxir bash -c 'cd /home/relaxir && source secrets.source && pg_dump -d relaxir -T foods'")
    File.write(path, data)
  end

  defp ssh({conn, _}, command) do
    IO.puts(">> #{command}")
    {:ok, chan} = :ssh_connection.session_channel(conn, :infinity)
    :success = :ssh_connection.exec(conn, chan, command, :infinity)
    {:ok, output} = receive_ssh(conn)
    {conn, output}
  end

  defp ssh(conn, command), do: ssh({conn, nil}, command)

  defp receive_ssh(conn, output \\ []) do
    receive do
      {:ssh_cm, ^conn, {:exit_status, _, 0}} ->
        {:ok, output}

      {:ssh_cm, ^conn, {:exit_status, _, _}} ->
        raise "SSH command failed"

      {:ssh_cm, ^conn, {:data, _, _, data}} ->
        receive_ssh(conn, [data | output])
    end
  end
end
