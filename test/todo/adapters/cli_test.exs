defmodule Todo.Adapters.CliTest do
  use ExUnit.Case
  import Mox

  alias Todo.Adapters.CliFormatter
  alias Todo.Core.TaskList
  alias Todo.Core.Task
  alias Todo.Adapters.Cli

  setup do
    :verify_on_exit!
    :ok
  end

  describe "when adding tasks" do
    test "should delegate adding tasks and format the result" do
      task_list = %TaskList{tasks: []}
      added_task_list = %TaskList{tasks: [%Task{description: "buy some milk"}]}

      expect(TaskListMock, :add_task_to_list, fn ^task_list,
                                                 %Task{description: "buy some milk"} ->
        added_task_list
      end)

      expect(CliFormatterMock, :format, fn ^added_task_list -> "example formatted tasks" end)

      added = Cli.parse(%TaskList{tasks: []}, {[], "add buy some milk"})
      assert added == {:ok, "example formatted tasks", "Added task"}
    end
  end

  describe "when marking tasks as done" do
    test "should delegate marking a task as done and format the result" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}
      done_task_list = %TaskList{tasks: [shopping, walk_dog, %Task{description: "cook dinner", is_done: true}]}

      expect(TaskListMock, :mark_task_as_done, fn ^task_list, 3 -> done_task_list end)
      expect(CliFormatterMock, :format, fn ^done_task_list -> "example formatted tasks" end)

      result = Cli.parse(task_list, {[], "done 3"})
      assert result == {:ok, "example formatted tasks", "Marked task 3 as done"}
    end
  end

  describe "when listing tasks" do
    test "should delegate formatting to the formatter for listing all tasks" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      expect(CliFormatterMock, :format, fn ^task_list -> "example formatted tasks" end)

      result = Cli.parse(task_list, {[], "list"})
      assert result == {:ok, "example formatted tasks"}
    end

    test "should delegate filtering and formatting for listing not-done tasks" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}
      not_done_task_list = %TaskList{tasks: [shopping, dinner]}

      expect(TaskListMock, :get_not_done_tasks, fn ^task_list ->
        not_done_task_list
      end)

      expect(CliFormatterMock, :format, fn ^not_done_task_list -> "example formatted tasks" end)

      result = Cli.parse(task_list, {[not_done: true], "list"})
      assert result == {:ok, "example formatted tasks"}
    end
  end

  describe "when removing tasks" do
    test "should delegate removing tasks and format the result" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}

      task_list = %TaskList{tasks: [shopping, walk_dog]}
      removed_task_list = %TaskList{tasks: [shopping]}

      expect(TaskListMock, :remove_task_from_list, fn ^task_list, 2 ->
        removed_task_list
      end)

      expect(CliFormatterMock, :format, fn ^removed_task_list -> "example formatted tasks" end)

      result = Cli.parse(task_list, {[], "remove 2"})
      assert result == {:ok, "example formatted tasks", "Removed task 2"}
    end
  end
end
