defmodule DumenuffEngine.Message do
  alias __MODULE__

  @enforce_keys [:from, :content]
  defstruct [:from, :content, :timestamp]

  def new(from, content) do
    {:ok, %Message{from: from, content: content, timestamp: :os.system_time(:seconds)}}
  end
end
