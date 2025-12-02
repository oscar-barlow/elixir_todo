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
    test "should delegate adding tasks" do
      task_list = %TaskList{tasks: []}

      expect(TaskListMock, :add_task_to_list, fn ^task_list,
                                                 %Task{description: "buy some milk"} ->
        %TaskList{tasks: [%Task{description: "buy some milk"}]}
      end)

      added = Cli.parse(%TaskList{tasks: []}, {[], "add buy some milk"})
      assert added == {:ok, "Added task"}
    end

  end

  describe "when marking tasks as done" do
    test "should delegate marking a task as done" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}
      _any_task_list = %TaskList{tasks: []}

      expect(TaskListMock, :mark_task_as_done, fn ^task_list, 3 -> _any_task_list end)

      result = Cli.parse(task_list, {[], "done 3"})
      assert result == {:ok, "Marked task 3 as done"}
    end

  end

  describe "when listing tasks" do
    test "should delegate formatting to the formatter for listing all tasks" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      expect(CliFormatterMock, :format, fn ^task_list -> "formatted output" end)

      result = Cli.parse(task_list, {[], "list"})
      assert result == {:ok, "formatted output"}
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

      expect(CliFormatterMock, :format, fn ^not_done_task_list -> "formatted output" end)

      result = Cli.parse(task_list, {[not_done: true], "list"})
      assert result == {:ok, "formatted output"}
    end
  end

  describe "when removing tasks" do
    test "should delegate removing tasks" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}

      task_list = %TaskList{tasks: [shopping, walk_dog]}

      expect(TaskListMock, :remove_task_from_list, fn ^task_list, 2 ->
        %TaskList{tasks: [shopping]}
      end)

      result = Cli.parse(task_list, {[], "remove 2"})
      assert result == {:ok, "Removed task 2"}
    end

  end
end
