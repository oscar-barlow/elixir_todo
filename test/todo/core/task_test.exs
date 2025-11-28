defmodule TaskTest do
  alias Todo.Core.Task
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
end
