defmodule ElixirTodoTest do
  alias ElixirTodo.TaskList
  alias ElixirTodo.Task
  use ExUnit.Case

  describe "task" do
    setup do
      task = %Task{description: "Test task"}
      {:ok, task: task}
    end

    test "has a name", %{task: task} do
      assert task.description == "Test task"
    end

    test "has a done status", %{task: task} do
      updated_task = %{task | is_done: true}
      assert updated_task.is_done
    end
  end

  describe "todolist" do
    setup do
      task = %Task{description: "Test task"}
      task_list = %TaskList{tasks: []}
      {:ok, task: task, task_list: task_list}
    end

    test "adds tasks to a list", %{task_list: task_list, task: task} do
      added = TaskList.add_task_to_list(task_list, task)
      assert Enum.any?(added.tasks, fn t -> t == task end)
      assert Enum.count(added.tasks) == 1
    end

    test "stops you adding not a task to a list", %{task_list: task_list} do
      not_a_task = %{some: "random map"}
      assert_raise FunctionClauseError, fn -> TaskList.add_task_to_list(task_list, not_a_task) end
    end

    test "updates done statuses of tasks in list", %{task_list: task_list} do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog"}
      dinner = %Task{description: "cook dinner"}

      Enum.each([shopping, walk_dog, dinner], fn task ->
        TaskList.add_task_to_list(task_list, task)
      end)
      
      TaskList.mark_task_as_done(task_list, 1)
      
      done_task = hd task_list
      
      assert done_task.is_done
    end

    test "returns you not-done tasks in list" do
      assert false
    end
  end
end
