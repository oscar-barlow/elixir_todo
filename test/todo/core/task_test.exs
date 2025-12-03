defmodule TaskTest do
  alias Todo.Core.Task
  use ExUnit.Case

  describe "task" do
    setup do
      task = Task.new("Test task")
      {:ok, task: task}
    end

    test "requires id and description" do
      assert_raise ArgumentError, fn ->
        struct!(Task, %{})
      end
    end

    test "Task.new/1 generates a task with an ID" do
      task = Task.new("Buy milk")
      
      assert task.description == "Buy milk"
      assert task.is_done == false
      assert is_binary(task.id)
      assert String.length(task.id) == 64  # SHA-256 hex is 64 chars
    end

    test "Task.new/1 generates deterministic IDs" do
      task1 = Task.new("Same description")
      task2 = Task.new("Same description")
      
      assert task1.id == task2.id
    end

    test "Task.new/1 generates different IDs for different descriptions" do
      task1 = Task.new("First task")
      task2 = Task.new("Second task")
      
      assert task1.id != task2.id
    end

    test "has a name", %{task: task} do
      assert task.description == "Test task"
    end

    test "has a done status", %{task: task} do
      updated_task = %{task | is_done: true}
      assert updated_task.is_done
    end
  end
end
