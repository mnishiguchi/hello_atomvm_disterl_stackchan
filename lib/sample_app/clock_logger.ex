defmodule SampleApp.ClockLogger do
  @moduledoc """
  Logs time once per second.
  """

  @timezone_name "JST"
  @timezone_offset_ms :timer.hours(9)

  @tick_interval_ms :timer.seconds(5)

  def start do
    spawn(fn -> tick_forever() end)
    :ok
  end

  defp tick_forever do
    print_local_time()

    receive do
      :stop ->
        :ok

      _ ->
        tick_forever()
    after
      @tick_interval_ms ->
        tick_forever()
    end
  end

  defp print_local_time do
    epoch_ms = :erlang.system_time(:millisecond)
    local_ms = epoch_ms + @timezone_offset_ms

    {{year, month, day}, {hour, minute, second}} =
      :calendar.system_time_to_universal_time(local_ms, :millisecond)

    :io.format(
      ~c"Date: ~4..0B/~2..0B/~2..0B ~2..0B:~2..0B:~2..0B (~pms) ~s~n",
      [year, month, day, hour, minute, second, epoch_ms, @timezone_name]
    )
  end
end
