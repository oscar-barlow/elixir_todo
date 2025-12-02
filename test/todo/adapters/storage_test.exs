defmodule StorageTest do
  use ExUnit.Case

  alias Todo.Adapters.Storage
  alias Todo.Core.Task
  alias Todo.Core.TaskList

  describe "when writing a file" do
    @tag :tmp_dir
    test "should create a todo file", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir}
      Storage.write(storage, "anything")

      assert File.exists?(Path.join(tmp_dir, "todo.txt"))
    end

    @tag :tmp_dir
    test "should overwrite the file", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir}
      Storage.write(storage, "anything")
      Storage.write(storage, "something")

      contents = File.read!(Path.join(storage.todo_folder, storage.todo_file))
      assert contents == "something"
    end
  end

  describe "when reading a file" do

    @tag :tmp_dir
    test "should create it if it doesn't exist already", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir}

      Storage.read(storage)

      todos_path = Path.join(tmp_dir, storage.todo_file)

      assert File.exists?(todos_path)
    end

    @tag :tmp_dir
    test "should return it as a TaskList", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir}

      todos = """
      1. do the shopping
      2. walk the dog ✓
      3. cook dinner
      4. shave
      """

      Storage.write(storage, todos)

      {:ok, task_list} = Storage.read(storage)

      assert task_list == %TaskList{tasks: [
        %Task{description: "do the shopping"},
        %Task{description: "walk the dog", is_done: true},
        %Task{description: "cook dinner"},
        %Task{description: "shave"},
      ]}
    end
  end
end
