defmodule Todo.Core.TaskListBehaviour do
  alias Todo.Core.TaskList
  alias Todo.Core.Task

  @callback add_task_to_list(TaskList.t(), Task.t()) :: TaskList.t()
  @callback mark_task_as_done(TaskList.t(), String.t()) :: TaskList.t()
  @callback get_not_done_tasks(TaskList.t()) :: TaskList.t()
  @callback remove_task_from_list(TaskList.t(), String.t()) :: TaskList.t()
end

defmodule Todo.Core.TaskList do
  @behaviour Todo.Core.TaskListBehaviour

  alias Todo.Core.TaskList
  alias Todo.Core.Task

  defstruct tasks: []

  @type t :: %__MODULE__{tasks: list(Task.t())}

  @impl true
  def add_task_to_list(%TaskList{} = task_list, %Task{} = task) do
    (task_list.tasks ++ [task])
    |> then(fn tasks -> %TaskList{tasks: tasks} end)
  end

  @impl true
  def mark_task_as_done(%TaskList{} = task_list, task_id) when is_binary(task_id) do
    case find_task_by_id(task_list, task_id) do
      nil -> raise Enum.OutOfBoundsError
      task -> mark_task_complete_and_create_new_task_list(task_list, task)
    end
  end

  defp find_task_by_id(%TaskList{} = task_list, task_id) do
    Enum.find(task_list.tasks, fn task -> task.id == task_id end)
  end

  defp mark_task_complete_and_create_new_task_list(%TaskList{} = task_list, %Task{} = task) do
    completed = %{task | is_done: true}
    updated_tasks = Enum.map(task_list.tasks, fn t -> 
      if t.id == task.id, do: completed, else: t
    end)
    %TaskList{tasks: updated_tasks}
  end

  @impl true
  def get_not_done_tasks(%TaskList{} = task_list) do
    not_done_tasks = Enum.filter(task_list.tasks, fn t -> !t.is_done end)
    %TaskList{tasks: not_done_tasks}
  end

  @impl true
  def remove_task_from_list(%TaskList{} = task_list, task_id) when is_binary(task_id) do
    Enum.reject(task_list.tasks, fn task -> task.id == task_id end)
    |> then(fn tasks -> %TaskList{tasks: tasks} end)
  end
end
