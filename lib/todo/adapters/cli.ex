defmodule Todo.Adapters.Cli do
  alias Todo.Core.Task
  alias Todo.Core.TaskList

  @task_list_module Application.compile_env(:elixir_todo, :task_list_module, Todo.Core.TaskList)
  @cli_formatter_module Application.compile_env(:elixir_todo, :cli_formatter_module, Todo.Adapters.CliFormatter)

  @behaviour Todo.Ports.Cli

  @impl true
  def parse(%TaskList{} = task_list, {opts, command}) do
    String.split(command)
    |> then(fn cmd -> run(task_list, opts, cmd) end)
  end

  defp run(%TaskList{} = task_list, [], ["add" | description_list]) do
    task = Enum.join(description_list, " ")
      |> then(fn description -> %Task{description: description} end)
    added = @task_list_module.add_task_to_list(task_list, task)
    {:ok, added, "Added task"}
  end

  defp run(%TaskList{} = task_list, [], ["done", index]) do
    done = @task_list_module.mark_task_as_done(task_list, String.to_integer(index))
    {:ok, done, "Marked task #{index} as done"}
  end

  defp run(%TaskList{} = task_list, [], ["list"]) do
    formatted = @cli_formatter_module.format(task_list)
    {:ok, formatted}
  end

  defp run(%TaskList{} = task_list, [not_done: true], ["list"]) do
    not_done_tasks = @task_list_module.get_not_done_tasks(task_list)
    formatted = @cli_formatter_module.format(not_done_tasks)
    {:ok, formatted}
  end

  defp run(%TaskList{} = task_list, [], ["remove", index]) do
    removed = @task_list_module.remove_task_from_list(task_list, String.to_integer(index))
    {:ok, removed, "Removed task #{index}"}
  end

end
