defmodule DumenuffEngine.Message do
  alias __MODULE__

  @enforce_keys [:from, :to, :content]
  defstruct [:from, :to, :content, :timestamp]

  # TODO as a when
  def new(from, to, content) do
    {:ok, %Message{from: from, to: to, content: content, timestamp: :os.system_time(:seconds)}}
  end

  # another clause for when from and to aren't players
  # def new(_from, _to, _content, _timestamp), do: {:error, :invalid_coordinate}
end
