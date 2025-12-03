defmodule Todo.Adapters.Storage do
  alias Todo.Core.TaskList
  alias Todo.Core.Task
  @behaviour Todo.Ports.Storage

  @formatter Application.compile_env(:todo, :formatter_module, Todo.Adapters.CliFormatter)

  @enforce_keys [:todo_folder, :todo_file]
  @type t :: %__MODULE__{todo_folder: Path.t(), todo_file: String.t()}

  defstruct todo_folder: nil, todo_file: nil

  @impl true
  def get(%__MODULE__{} = storage) do
    read_path = Path.join(storage.todo_folder, storage.todo_file)

    case File.exists?(read_path) do
      true -> :ok
      false -> File.touch(read_path, System.os_time(:second))
    end

    task_list =
      File.stream!(read_path, encoding: :utf8)
      |> Stream.map(&convert_line_to_task/1)
      |> Enum.to_list()
      |> then(fn tasks -> %TaskList{tasks: tasks} end)

    {:ok, task_list}
  end

  defp convert_line_to_task(line) when is_binary(line) do
    line
    |> String.trim
    |> String.split
    |> tl
    |> parse_task
  end

  defp parse_task(parts) when is_list(parts) do
    case List.pop_at(parts, -1) do
      {"✓", description_parts} ->
        description = Enum.join(description_parts, " ")
        Task.new(description) |> then(fn task -> %{task | is_done: true} end)

      {last_word, description_parts} ->
        description = Enum.join(description_parts ++ [last_word], " ")
        Task.new(description)
    end
  end

  @impl true
  def save(%__MODULE__{} = storage, %TaskList{} = task_list) do
    write_path = Path.join(storage.todo_folder, storage.todo_file)
    contents = @formatter.format(task_list)
    File.write!(write_path, contents)
    :ok
  end
end
