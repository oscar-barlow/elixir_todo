defmodule Todo.Main do

  alias Todo.Adapters.Cli
  alias Todo.Adapters.Storage
  def main(args \\ []) do
    args
      |> parse
      |> IO.puts
  end

  defp parse(args) do
    {_, word, _} = args |> OptionParser.parse(switches: [not_done: :boolean])
    storage = %Storage{}
    {:ok, task_list} = Storage.read(storage)
    command = Enum.join(word, " ")
    {:ok, updated} = Cli.parse(task_list, command)
    Storage.write(storage, updated)
    updated
  end
end
