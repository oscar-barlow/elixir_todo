defmodule Todo.Adapters.Cli do
  alias Todo.Core.Task
  alias Todo.Core.TaskList
  
  @task_list_module Application.compile_env(:elixir_todo, :task_list_module, Todo.Core.TaskList)
  
  @behaviour Todo.Ports.Cli
  
  # this module should actually format the tasks, so that we're always returning a string
  # then orchestration code can figure just take input and print output
  # my storage adapter should be responsible for saving and formatting files to disk, and reading files into tasklists
  # possibly the formatter needs to live in its own module.
	
  @impl true
  def parse(%TaskList{} = task_list, command) do
    String.split(command)
    |> then(fn cmd -> run(task_list, cmd) end)
  end
  
  defp run(%TaskList{} = task_list, ["add" | description_list]) do
    task = Enum.join(description_list, " ")
      |> then(fn description -> %Task{description: description} end)
    added = @task_list_module.add_task_to_list(task_list, task)
    IO.puts("Added task")
    added
  end
  
  defp run(%TaskList{} = task_list, ["done", index]) do
    done = @task_list_module.mark_task_as_done(task_list, String.to_integer(index))
    IO.puts("Marked task as done")
    done
  end
  
  defp run(%TaskList{} = task_list, ["list"]) do
    task_list.tasks
    |> Enum.each(&IO.puts(&1.description))
    :ok
  end
  
  defp run(%TaskList{} = task_list, ["list", "--not-done"]) do
    @task_list_module.get_not_done_tasks(task_list)
    |> Map.get(:tasks)
    |> Enum.each(&IO.puts(&1.description))
    :ok
  end
  
  defp run(%TaskList{} = task_list, ["remove", index]) do
    removed = @task_list_module.remove_task_from_list(task_list, String.to_integer(index))
    IO.puts("Removed task from list")
    removed
  end
  
end