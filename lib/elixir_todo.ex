defmodule ElixirTodo do
  @moduledoc """
  Documentation for `ElixirTodo`.
  """

  defmodule Task do
    defstruct description: "", is_done: false
  end

  defmodule TaskList do
    defstruct tasks: []

    def add_task_to_list(%TaskList{} = task_list, %Task{} = task) do
      %TaskList{tasks: [task | task_list.tasks]}
    end

    def mark_task_as_done(%TaskList{} = task_list, index) when is_integer(index) do
      case Enum.fetch(task_list.tasks, index - 1) do
        :error -> raise Enum.OutOfBoundsError
        {:ok, task} ->
          completed = %Task{description: task.description, is_done: true}
          updated_tasks = List.replace_at(task_list.tasks, index - 1, completed)
          %TaskList{tasks: updated_tasks}
      end
    end

    def get_not_done_tasks(%TaskList{} = task_list) do
      not_done_tasks = Enum.filter(task_list.tasks, fn t -> !t.is_done end)
      %TaskList{tasks: not_done_tasks}
    end
  end
end
