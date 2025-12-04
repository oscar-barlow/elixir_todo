defmodule TaskListTest do
  alias Todo.Core.TaskList
  alias Todo.Core.Task
  use ExUnit.Case

  describe "todolist" do
    setup do
      task = Task.new("Test task")
      task_list = %TaskList{tasks: []}
      {:ok, task: task, task_list: task_list}
    end

    test "adds tasks to a list", %{task_list: task_list, task: task} do
      {:ok, added} = TaskList.add_task_to_list(task_list, task)
      assert Enum.any?(added.tasks, fn t -> t == task end)
      assert Enum.count(added.tasks) == 1
    end

    test "prevents adding duplicate tasks", %{task_list: task_list, task: task} do
      {:ok, added} = TaskList.add_task_to_list(task_list, task)
      assert TaskList.add_task_to_list(added, task) == {:error, :duplicate_task}
    end

    test "preserves task order when adding tasks to a list", %{task_list: task_list, task: task} do
      another_task = Task.new("Another test task")

      {:ok, with_first} = TaskList.add_task_to_list(task_list, task)
      {:ok, result} = TaskList.add_task_to_list(with_first, another_task)

      assert result == %TaskList{tasks: [task, another_task]}
    end

    # todo: should be deprecated by spec and dialyzer
    test "stops you adding not a task to a list", %{task_list: task_list} do
      not_a_task = %{some: "random map"}
      assert_raise FunctionClauseError, fn -> TaskList.add_task_to_list(task_list, not_a_task) end
    end

    test "updates done statuses of tasks in list" do
      shopping = Task.new("do the shopping")
      walk_dog = Task.new("walk the dog")
      dinner = Task.new("cook dinner")

      {:ok, with_shopping} = TaskList.add_task_to_list(%TaskList{}, shopping)
      {:ok, with_walk_dog} = TaskList.add_task_to_list(with_shopping, walk_dog)
      {:ok, task_list} = TaskList.add_task_to_list(with_walk_dog, dinner)

      {:ok, completed_first_task} = TaskList.mark_task_as_done(task_list, shopping.id)

      done_task = hd(completed_first_task.tasks)

      assert done_task.is_done
    end

    test "prevents you marking non-existent tasks as done", %{task_list: task_list} do
      assert TaskList.mark_task_as_done(task_list, "nonexistent-id") == {:error, :task_not_found}
    end

    test "prevents you marking already done tasks as done" do
      shopping = Task.new("do the shopping")
      {:ok, task_list} = TaskList.add_task_to_list(%TaskList{}, shopping)
      {:ok, marked_done} = TaskList.mark_task_as_done(task_list, shopping.id)

      assert TaskList.mark_task_as_done(marked_done, shopping.id) == {:error, :already_done}
    end

    test "returns you not-done tasks in list" do
      shopping = Task.new("do the shopping")
      walk_dog = Task.new("walk the dog", true)
      dinner = Task.new("cook dinner")

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      not_done_tasks = TaskList.get_not_done_tasks(task_list)
      assert not_done_tasks == %TaskList{tasks: [shopping, dinner]}
    end

    test "removes a task from the list" do
      shopping = Task.new("do the shopping")
      walk_dog = Task.new("walk the dog", true)
      dinner = Task.new("cook dinner")

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      {:ok, remaining_tasks} = TaskList.remove_task_from_list(task_list, shopping.id)
      assert remaining_tasks == %TaskList{tasks: [walk_dog, dinner]}
    end

    test "removes the correct task from middle of the list" do
      shopping = Task.new("do the shopping")
      walk_dog = Task.new("walk the dog")
      dinner = Task.new("cook dinner")

      task_list = %TaskList{tasks: [shopping, walk_dog, dinner]}

      {:ok, remaining_tasks} = TaskList.remove_task_from_list(task_list, walk_dog.id)
      assert remaining_tasks == %TaskList{tasks: [shopping, dinner]}
    end

    test "prevents you removing non-existent tasks", %{task_list: task_list} do
      assert TaskList.remove_task_from_list(task_list, "nonexistent-id") == {:error, :task_not_found}
    end
  end
end
