defmodule Todo.Adapters.CliFormatterTest do
  alias Todo.Adapters.CliFormatter
  alias Todo.Core.Task
  alias Todo.Core.TaskList

  use ExUnit.Case

  test "should format tasks" do
    shopping = %Task{description: "do the shopping"}
    walk_dog = %Task{description: "walk the dog", is_done: true}
    dinner = %Task{description: "cook dinner"}

    task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

    result = CliFormatter.format(task_list)

    expected = """
    1. do the shopping
    2. walk the dog ✓
    3. cook dinner
    """

    assert result == expected
  end
end
