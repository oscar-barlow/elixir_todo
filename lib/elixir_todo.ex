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
      %ElixirTodo.TaskList{tasks: [task | task_list.tasks]}
    end
    
    def mark_task_as_done(%TaskList{} = task_list, index) when is_integer(index) do
      task = Enum.fetch(task_list.tasks, index)
      task.is_done = true
      List.keyreplace(task_list.tasks, index, task)
      task = task_list.tasks[index]
      task.is_done = true
    end
  end
end
