defmodule Todo.Adapters.Cli do
  alias Todo.Core.Task
  alias Todo.Core.TaskList

  @task_list_module Application.compile_env(:elixir_todo, :task_list_module, Todo.Core.TaskList)
  @cli_formatter_module Application.compile_env(:elixir_todo, :cli_formatter_module, Todo.Adapters.CliFormatter)

  @behaviour Todo.Ports.Cli

  # this module should actually format the tasks, so that we're always returning a string
  # then orchestration code can figure just take input and print output
  # my storage adapter should be responsible for saving and formatting files to disk, and reading files into tasklists
  # possibly the formatter needs to live in its own module.

  @impl true
  def parse(%TaskList{} = task_list, command) do
    String.split(command)
    |> then(&run(task_list, &1))

  end

  defp run(%TaskList{} = task_list, ["add" | description_list]) do
    task = Enum.join(description_list, " ")
      |> then(fn description -> %Task{description: description} end)
    @task_list_module.add_task_to_list(task_list, task)
    {:ok, "Added task"}
  end

  defp run(%TaskList{} = task_list, ["done", index]) do
    @task_list_module.mark_task_as_done(task_list, String.to_integer(index))
    {:ok, "Marked task #{index} as done"}
  end

  defp run(%TaskList{} = task_list, ["list"]) do
    formatted = @cli_formatter_module.format(task_list)
    {:ok, formatted}
  end

  defp run(%TaskList{} = task_list, ["list", "--not-done"]) do
    not_done_tasks = @task_list_module.get_not_done_tasks(task_list)
    formatted = @cli_formatter_module.format(not_done_tasks)
    {:ok, formatted}
  end

  defp run(%TaskList{} = task_list, ["remove", index]) do
    @task_list_module.remove_task_from_list(task_list, String.to_integer(index))
    {:ok, "Removed task #{index}"}
  end

end
