defmodule Todo.Core.TaskList do
  alias Todo.Core.TaskList
  alias Todo.Core.Task

  defstruct tasks: []

  def add_task_to_list(%TaskList{} = task_list, %Task{} = task) do
    %TaskList{tasks: [task | task_list.tasks]}
  end

  def mark_task_as_done(%TaskList{} = task_list, index) when is_integer(index) do
    case Enum.fetch(task_list.tasks, index - 1) do
      :error -> raise Enum.OutOfBoundsError
      {:ok, task} -> mark_task_complete_and_create_new_task_list(task_list, task, index)
    end
  end

  defp mark_task_complete_and_create_new_task_list(%TaskList{} = task_list, %Task{} = task, index) do
    completed = %Task{description: task.description, is_done: true}
    updated_tasks = List.replace_at(task_list.tasks, index - 1, completed)
    %TaskList{tasks: updated_tasks}
  end

  def get_not_done_tasks(%TaskList{} = task_list) do
    not_done_tasks = Enum.filter(task_list.tasks, fn t -> !t.is_done end)
    %TaskList{tasks: not_done_tasks}
  end

  def remove_task_from_list(%TaskList{} = task_list, index) when is_integer(index) do
    Enum.drop(task_list.tasks, index)
    |> then(fn tasks -> %TaskList{tasks: tasks} end)
  end
end
