defmodule Todo.Adapters.Cli do
  alias Todo.Core.TaskList
  alias Todo.Core.Task
  
  @behaviour Todo.Ports.Cli
	
  @impl true
  def parse(%TaskList{} = task_list, command) do
    String.split(command)
    |> then(fn cmd -> run(task_list, cmd) end)
  end
  
  defp run(%TaskList{} = task_list, ["add" | description_list]) do
    task = Enum.join(description_list)
      |> then(fn description -> %Task{description: description} end)
    added = TaskList.add_task_to_list(task_list, task)
    IO.puts("Added task")
    added
  end
  
  defp run(%TaskList{} = task_list, ["done", index]) do
    done = TaskList.mark_task_as_done(task_list, index)
    IO.puts("Marked task as done")
    done
  end
  
  defp run(%TaskList{} = task_list, ["list"]) do
    task_list.tasks
    |> Enum.each(&IO.puts(&1.description))
    :ok
  end
  
  defp run(%TaskList{} = task_list, ["list", "--not-done"]) do
    TaskList.get_not_done_tasks(task_list)
    |> Map.get(:tasks)
    |> Enum.each(&IO.puts(&1.description))
    :ok
  end
  
  defp run(%TaskList{} = task_list, ["remove", index]) do
    removed = TaskList.remove_task_from_list(task_list, index)
    IO.puts("Removed task from list")
    removed
  end
  
end