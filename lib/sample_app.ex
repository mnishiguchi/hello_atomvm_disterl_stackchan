defmodule SampleApp do
  @moduledoc """
  Entry point for the AtomVM application.
  """

  def start do
    SampleApp.Provision.maybe_provision()
    {:ok, _} = SampleApp.DistErl.start_link()
    {:ok, _} = SampleApp.WiFi.start_link()
    {:ok, _} = SampleApp.ClockLogger.start_link()

    Process.sleep(:infinity)
  end
end
