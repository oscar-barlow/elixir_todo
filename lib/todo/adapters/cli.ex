defmodule Todo.Adapters.Cli do
  alias Todo.Core.Task
  alias Todo.Core.TaskList

  @task_list_module Application.compile_env(:todo, :task_list_module, Todo.Core.TaskList)
  @cli_formatter_module Application.compile_env(
                          :todo,
                          :cli_formatter_module,
                          Todo.Adapters.CliFormatter
                        )

  @behaviour Todo.Ports.Cli

  @impl true
  def parse(%TaskList{} = task_list, {opts, command}) do
    String.split(command)
    |> then(fn cmd -> run(task_list, opts, cmd) end)
    |> format_result()
  end

  defp get_task_id_at_position(%TaskList{} = task_list, index) when is_integer(index) do
    case Enum.fetch(task_list.tasks, index - 1) do
      {:ok, task} -> {:ok, task.id}
      :error -> {:error, :task_not_found}
    end
  end

  defp run(%TaskList{} = task_list, [], ["add" | description_list]) do
    description = Enum.join(description_list, " ")
    task = Task.new(description)
    added = @task_list_module.add_task_to_list(task_list, task)
    {:ok, added, "Added task"}
  end

  defp run(%TaskList{} = task_list, [], ["done", index]) do
    index_int = String.to_integer(index)

    case get_task_id_at_position(task_list, index_int) do
      {:ok, task_id} ->
        done = @task_list_module.mark_task_as_done(task_list, task_id)
        {:ok, done, "Marked task #{index} as done"}
      {:error, :task_not_found} ->
        {:error, "Task #{index} not found"}
    end
  end

  defp run(%TaskList{} = task_list, [], ["list"]) do
    {:ok, task_list}
  end

  defp run(%TaskList{} = task_list, [not_done: true], ["list"]) do
    not_done_tasks = @task_list_module.get_not_done_tasks(task_list)
    {:ok, not_done_tasks}
  end

  defp run(%TaskList{} = task_list, [], ["remove", index]) do
    index_int = String.to_integer(index)

    case get_task_id_at_position(task_list, index_int) do
      {:ok, task_id} ->
        removed = @task_list_module.remove_task_from_list(task_list, task_id)
        {:ok, removed, "Removed task #{index}"}
      {:error, :task_not_found} ->
        {:error, "Task #{index} not found"}
    end
  end

  defp run(%TaskList{} = task_list, [], ["help"]) do
    help = """
    todo - a mini cli-based todo app written in Elixir.

    todo will persist a list of tasks to 'todo.txt' in your home directory.

    USAGE:
      todo <command> [arguments]

    COMMANDS:
      add <description>       Add a new task
      done <number>           Mark a task as complete
      list                    Show all tasks
      list --not-done         Show only incomplete tasks
      remove <number>         Remove a task
      help                    Show this help text

    EXAMPLES:
      todo add Buy groceries
      todo done 1
      todo list
      todo remove 3
    """

    {:ok, task_list, help}
  end

  defp format_result({:ok, %TaskList{} = task_list, description}) do
    formatted = @cli_formatter_module.format(task_list)
    {:ok, formatted, description}
  end

  defp format_result({:ok, %TaskList{} = task_list}) do
    formatted = @cli_formatter_module.format(task_list)
    {:ok, formatted}
  end

  defp format_result({:error, message}) do
    {:error, message}
  end
end
