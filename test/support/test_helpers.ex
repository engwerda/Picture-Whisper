defmodule PictureWhisperWeb.TestHelpers do
  import ExUnit.Assertions

  def assert_async_result(assertion_fun, timeout \\ 5000) do
    start_time = System.monotonic_time(:millisecond)
    assert_loop(assertion_fun, start_time, timeout)
  end

  defp assert_loop(assertion_fun, start_time, timeout) do
    case assertion_fun.() do
      {:ok, result} ->
        result

      :retry ->
        if System.monotonic_time(:millisecond) - start_time < timeout do
          :timer.sleep(100)
          assert_loop(assertion_fun, start_time, timeout)
        else
          flunk("Timed out waiting for async result")
        end
    end
  end
end
