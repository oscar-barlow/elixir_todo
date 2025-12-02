defmodule Todo.Core.TaskListBehaviour do
  alias Todo.Core.TaskList
  alias Todo.Core.Task

  @callback add_task_to_list(TaskList.t(), Task.t()) :: TaskList.t()
	@callback mark_task_as_done(TaskList.t(), integer()) :: TaskList.t()
	@callback get_not_done_tasks(TaskList.t()) :: TaskList.t()
	@callback remove_task_from_list(TaskList.t(), integer()) :: TaskList.t()
end

defmodule Todo.Core.TaskList do
  @behaviour Todo.Core.TaskListBehaviour

  alias Todo.Core.TaskList
  alias Todo.Core.Task

  defstruct tasks: []

  @type t :: %__MODULE__ {tasks: list(Task.t())}

  @impl true
  def add_task_to_list(%TaskList{} = task_list, %Task{} = task) do
    task_list.tasks ++ [task]
    |> then(&(%TaskList{tasks: &1}))
  end

  @impl true
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

  @impl true
  def get_not_done_tasks(%TaskList{} = task_list) do
    not_done_tasks = Enum.filter(task_list.tasks, fn t -> !t.is_done end)
    %TaskList{tasks: not_done_tasks}
  end

  @impl true
  def remove_task_from_list(%TaskList{} = task_list, index) when is_integer(index) do
    List.delete_at(task_list.tasks, index - 1)
    |> then(fn tasks -> %TaskList{tasks: tasks} end)
  end
end
