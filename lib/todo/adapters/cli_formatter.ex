defmodule Todo.Adapters.CliFormatter do
  @behaviour Todo.Ports.CliFormatter

  alias Todo.Core.TaskList
  alias Todo.Core.Task

  @impl true
  def format(%TaskList{tasks: []}) do
    ""
  end

  @impl true
  def format(%TaskList{tasks: tasks}) do
    new_line = "\n"

    result =
      tasks
      |> Enum.with_index(1)
      |> Enum.map_join(new_line, &format_task/1)

    result <> new_line
  end

  defp format_task({%Task{description: description, is_done: true}, index}) do
    "#{index}. #{description} ✓"
  end

  defp format_task({%Task{description: description, is_done: false}, index}) do
    "#{index}. #{description}"
  end
end
