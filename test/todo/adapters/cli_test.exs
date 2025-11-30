defmodule Todo.Adapters.CliTest do
  use ExUnit.Case
  import Mox
  
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
      
      expect(TaskListMock, :add_task_to_list, fn ^task_list, %Task{description: "buy some milk"} ->
        %TaskList{tasks: [%Task{description: "buy some milk"}]}
      end)
      
      Cli.parse(%TaskList{tasks: []}, "add buy some milk")
    end

    test "should return task list with task added" do
      task_list = %TaskList{tasks: []}
      
      expect(TaskListMock, :add_task_to_list, fn ^task_list, %Task{description: "buy some milk"} ->
        %TaskList{tasks: [%Task{description: "buy some milk"}]}
      end)
      
      result = Cli.parse(%TaskList{tasks: []}, "add buy some milk")
      expected = """
      1. buy some milk
      """
      
      assert result == expected
    end
  end

  describe "when listing tasks" do
    test "should list all tasks" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}
      
      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}
      
      result = Cli.parse(task_list, "list")
      expected = """
      1. do the shopping
      2. walk the dog ✓
      3. cook dinner
      """
      
      assert result == expected
    end

    test "should list only not-done tasks, given flag is passed" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}
      
      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}
      
      expect(TaskListMock, :get_not_done_tasks, fn ^task_list -> %TaskList{tasks: [shopping, dinner]} end)
      
      result = Cli.parse(task_list, "list --not-done")
      expected = """
      1. do the shopping
      2. cook dinner
      """
      
      assert result == expected
    end
  end
  
  describe "when removing tasks" do
    test "should delegate removing tasks" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      
      task_list = %TaskList{tasks: [shopping, walk_dog]}
      
      expect(TaskListMock, :remove_task_from_list, fn ^task_list, 2 -> %TaskList{tasks: [shopping]} end)
    
      Cli.parse(task_list, "remove 2")
    end
    
    test "should return task list without removed task" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      
      task_list = %TaskList{tasks: [shopping, walk_dog]}
      
      expect(TaskListMock, :remove_task_from_list, fn ^task_list, 2 -> %TaskList{tasks: [shopping]} end)
    
      result = Cli.parse(task_list, "remove 2")
      
      expected = """
      1. do the shopping
      """
      
      assert result == expected
    end
  end
end
