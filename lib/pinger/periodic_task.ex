defmodule Pinger.PeriodicTask do
  require Logger

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    start_msg = "starting ping for #{state.url}"
    IO.puts start_msg
    Logger.info fn ->
      start_msg
    end

    spawn_link(fn -> ping(state.url) end)
    schedule_work()

    {:ok, state}
  end

  def handle_info(:work, state) do
    spawn_link(fn -> ping(state.url) end)

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 5 * 60 * 1000)
  end

  defp ping(url) do
    msg = case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        "#{url} is ok :)"
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        "#{url} not found :("
      {:ok, %HTTPoison.Response{status_code: 301}} ->
        "#{url} is a redirect."
      {:error, %HTTPoison.Error{reason: reason}} ->
        "#{url} error: #{reason}"
      {:ok, %HTTPoison.Response{status_code: code}} ->
        "#{url} unhandled code: #{code}"
    end

    Logger.info fn ->
      msg
    end
  end

end
