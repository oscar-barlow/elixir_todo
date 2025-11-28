defmodule TaskListTest do
  alias Todo.Core.TaskList
  alias Todo.Core.Task
  use ExUnit.Case

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

    test "updates done statuses of tasks in list" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog"}
      dinner = %Task{description: "cook dinner"}

      task_list =
        %TaskList{}
        |> TaskList.add_task_to_list(shopping)
        |> TaskList.add_task_to_list(walk_dog)
        |> TaskList.add_task_to_list(dinner)

      completed_first_task = TaskList.mark_task_as_done(task_list, 1)

      done_task = hd completed_first_task.tasks

      assert done_task.is_done
    end

    test "prevents you marking non-existent tasks as done", %{task_list: task_list} do
      assert_raise Enum.OutOfBoundsError, fn ->
        TaskList.mark_task_as_done(task_list, 0)
      end
    end

    test "returns you not-done tasks in list" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      not_done_tasks = TaskList.get_not_done_tasks(task_list)
      assert not_done_tasks == %TaskList{tasks: [shopping, dinner]}
    end

    test "removes a task from the list" do
      shopping = %Task{description: "do the shopping"}
      walk_dog = %Task{description: "walk the dog", is_done: true}
      dinner = %Task{description: "cook dinner"}

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      remaining_tasks = TaskList.remove_task_from_list(task_list, 1)
      assert remaining_tasks == %TaskList{tasks: [walk_dog, dinner]}
    end
  end

end
