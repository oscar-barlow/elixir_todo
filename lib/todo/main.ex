defmodule Todo.Main do
  alias Todo.Adapters.Cli
  alias Todo.Adapters.Storage

  def main(args \\ []) do
    args
    |> parse
    |> IO.puts
  end

  defp parse(args) do
    {opts, word, _} = args |> OptionParser.parse(switches: [not_done: :boolean])
    storage = %Storage{todo_folder: Path.expand("~"), todo_file: "todo.txt"}
    {:ok, task_list} = Storage.read(storage)
    command = Enum.join(word, " ")

     case Cli.parse(task_list, {opts, command}) do
       {:ok, updated, desc} ->
          Storage.write(storage, updated)
          desc
        {:ok, listed} ->
          listed
     end
  end

end
