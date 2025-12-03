defmodule Todo.Adapters.Storage do
  alias Todo.Core.TaskList
  alias Todo.Core.Task
  @behaviour Todo.Ports.Storage

  @enforce_keys [:todo_folder, :todo_file]
  @type t :: %__MODULE__{todo_folder: Path.t(), todo_file: String.t()}

  defstruct todo_folder: nil, todo_file: nil

  @impl true
  def read(%__MODULE__{} = storage) do
    read_path = Path.join(storage.todo_folder, storage.todo_file)

    case File.exists?(read_path) do
      true -> :ok
      false -> File.touch(read_path, System.os_time(:second))
    end


    task_list =
      File.stream!(read_path, encoding: :utf8)
      |> Stream.map(&convert_line_to_task/1)
      |> Enum.to_list
      |> then(fn tasks -> %TaskList{tasks: tasks} end)

    {:ok, task_list}
  end

  defp convert_line_to_task(line) do
    line
    |> String.trim
    |> String.split
    |> tl
    |> parse_task
  end

  defp parse_task(parts) do
    case List.pop_at(parts, -1) do
      {"✓", description_parts} ->
        %Task{description: Enum.join(description_parts, " "), is_done: true}

      {last_word, description_parts} ->
        %Task{description: Enum.join(description_parts ++ [last_word], " ")}
    end
  end

  @impl true
  def write(%__MODULE__{} = storage, contents) do
    write_path = Path.join(storage.todo_folder, storage.todo_file)
    File.write!(write_path, contents)
    :ok
  end
end
