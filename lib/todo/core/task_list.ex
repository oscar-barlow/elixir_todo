defmodule Todo.Core.TaskListBehaviour do
  alias Todo.Core.TaskList
  alias Todo.Core.Task

  @callback add_task_to_list(TaskList.t(), Task.t()) :: {:ok, TaskList.t()} | {:error, :duplicate_task}
  @callback mark_task_as_done(TaskList.t(), String.t()) :: {:ok, TaskList.t()} | {:error, :task_not_found | :already_done}
  @callback get_not_done_tasks(TaskList.t()) :: TaskList.t()
  @callback remove_task_from_list(TaskList.t(), String.t()) :: {:ok, TaskList.t()} | {:error, :task_not_found}
end

defmodule Todo.Core.TaskList do
  @behaviour Todo.Core.TaskListBehaviour

  alias Todo.Core.TaskList
  alias Todo.Core.Task

  defstruct tasks: []

  @type t :: %__MODULE__{tasks: list(Task.t())}

  @impl true
  def add_task_to_list(%TaskList{} = task_list, %Task{} = task) do
    case validate_not_duplicate(task_list, task) do
      :ok ->
        tasks = task_list.tasks ++ [task]
        {:ok, %TaskList{tasks: tasks}}

      error -> error
    end
  end

  defp validate_not_duplicate(%TaskList{tasks: tasks}, %Task{id: id}) do
    case Enum.any?(tasks, fn t -> t.id == id end) do
      true -> {:error, :duplicate_task}
      false -> :ok
    end
  end

  @impl true
  def mark_task_as_done(%TaskList{} = task_list, task_id) when is_binary(task_id) do
    case find_task_by_id(task_list, task_id) do
      nil ->
        {:error, :task_not_found}

      %Task{is_done: true} ->
        {:error, :already_done}

      task ->
        updated_list = mark_task_complete_and_create_new_task_list(task_list, task)
        {:ok, updated_list}
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
    case find_task_by_id(task_list, task_id) do
      nil ->
        {:error, :task_not_found}

      _task ->
        tasks = Enum.reject(task_list.tasks, fn task -> task.id == task_id end)
        {:ok, %TaskList{tasks: tasks}}
    end
  end
end
