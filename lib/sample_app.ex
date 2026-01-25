defmodule SampleApp do
  @moduledoc """
  Entry point for the AtomVM application.
  """

  def start do
    SampleApp.Provision.maybe_provision()
    SampleApp.WiFi.start()
    {:ok, _pid} = SampleApp.ClockLogger.start_link()

    Process.sleep(:infinity)
  end
end
