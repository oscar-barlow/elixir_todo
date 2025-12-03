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
      added_task_list = %TaskList{tasks: [Task.new("buy some milk")]}

      expect(TaskListMock, :add_task_to_list, fn ^task_list,
                                                 %Task{description: "buy some milk"} ->
        {:ok, added_task_list}
      end)

      expect(CliFormatterMock, :format, fn ^added_task_list -> "example formatted tasks" end)

      added = Cli.parse(%TaskList{tasks: []}, {[], "add buy some milk"})
      assert added == {:ok, "example formatted tasks", "Added task"}
    end
  end

  describe "when marking tasks as done" do
    test "should delegate marking a task as done and format the result" do
      shopping = Task.new("do the shopping")
      walk_dog = Task.new("walk the dog", true)
      dinner = Task.new("cook dinner")

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      done_task_list = %TaskList{
        tasks: [shopping, walk_dog, Task.new("cook dinner", true)]
      }

      expect(TaskListMock, :mark_task_as_done, fn ^task_list, task_id ->
        assert task_id == dinner.id
        {:ok, done_task_list}
      end)
      expect(CliFormatterMock, :format, fn ^done_task_list -> "example formatted tasks" end)

      result = Cli.parse(task_list, {[], "done 3"})
      assert result == {:ok, "example formatted tasks", "Marked task 3 as done"}
    end

    test "should return error when task index not found" do
      shopping = Task.new("do the shopping")
      task_list = %TaskList{tasks: [shopping]}

      result = Cli.parse(task_list, {[], "done 5"})
      assert result == {:error, "Task 5 not found"}
    end
  end

  describe "when listing tasks" do
    test "should delegate formatting to the formatter for listing all tasks" do
      shopping = Task.new("do the shopping")
      walk_dog = Task.new("walk the dog", true)
      dinner = Task.new("cook dinner")

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      expect(CliFormatterMock, :format, fn ^task_list -> "example formatted tasks" end)

      result = Cli.parse(task_list, {[], "list"})
      assert result == {:ok, "example formatted tasks"}
    end

    test "should delegate filtering and formatting for listing not-done tasks" do
      shopping = Task.new("do the shopping")
      walk_dog = Task.new("walk the dog", true)
      dinner = Task.new("cook dinner")

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
      shopping = Task.new("do the shopping")
      walk_dog = Task.new("walk the dog", true)

      task_list = %TaskList{tasks: [shopping, walk_dog]}
      removed_task_list = %TaskList{tasks: [shopping]}

      expect(TaskListMock, :remove_task_from_list, fn ^task_list, task_id ->
        assert task_id == walk_dog.id
        {:ok, removed_task_list}
      end)

      expect(CliFormatterMock, :format, fn ^removed_task_list -> "example formatted tasks" end)

      result = Cli.parse(task_list, {[], "remove 2"})
      assert result == {:ok, "example formatted tasks", "Removed task 2"}
    end

    test "should return error when task index not found" do
      shopping = Task.new("do the shopping")
      task_list = %TaskList{tasks: [shopping]}

      result = Cli.parse(task_list, {[], "remove 10"})
      assert result == {:error, "Task 10 not found"}
    end
  end
end
