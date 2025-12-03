defmodule Todo.Adapters.CliFormatterTest do
  alias Todo.Adapters.CliFormatter
  alias Todo.Core.Task
  alias Todo.Core.TaskList

  use ExUnit.Case

  test "should format tasks" do
    shopping = Task.new("do the shopping")
    walk_dog = Task.new("walk the dog", true)
    dinner = Task.new("cook dinner")

    task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

    result = CliFormatter.format(task_list)

    expected = """
    1. do the shopping
    2. walk the dog ✓
    3. cook dinner
    """

    assert result == expected
  end

  test "should format empty task list" do
    emtpy_task_list = %TaskList{}
    result = CliFormatter.format(emtpy_task_list)
    assert result == ""
  end
end
