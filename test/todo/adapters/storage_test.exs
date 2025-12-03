defmodule StorageTest do
  use ExUnit.Case
  import Mox

  alias Todo.Adapters.Storage
  alias Todo.Core.Task
  alias Todo.Core.TaskList

  setup do
    :verify_on_exit!
    :ok
  end

  describe "storage struct" do
    test "requires todo_folder and todo_file" do
      assert_raise ArgumentError, fn ->
        struct!(Storage, %{})
      end
    end
  end

  describe "when saving a file" do
    @tag :tmp_dir
    test "should create a todo file", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir, todo_file: "todo.txt"}
      task_list = %TaskList{tasks: [Task.new("test task")]}

      expect(CliFormatterMock, :format, fn ^task_list -> "formatted output" end)

      Storage.save(storage, task_list)

      assert File.exists?(Path.join(tmp_dir, "todo.txt"))
    end

    @tag :tmp_dir
    test "should overwrite the file", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir, todo_file: "todo.txt"}
      task_list1 = %TaskList{tasks: [Task.new("first task")]}
      task_list2 = %TaskList{tasks: [Task.new("second task")]}

      expect(CliFormatterMock, :format, fn ^task_list1 -> "some formatted output" end)
      expect(CliFormatterMock, :format, fn ^task_list2 -> "some more formatted output" end)

      Storage.save(storage, task_list1)
      Storage.save(storage, task_list2)

      contents = File.read!(Path.join(storage.todo_folder, storage.todo_file))
      assert contents == "some more formatted output"
    end

    @tag :tmp_dir
    test "should write an empty file if the task list is empty", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir, todo_file: "todo.txt"}
      empty_list = %TaskList{tasks: []}

      expect(CliFormatterMock, :format, fn ^empty_list -> "" end)

      Storage.save(storage, empty_list)
      contents = File.read!(Path.join(storage.todo_folder, storage.todo_file))
      assert contents == ""
    end
  end

  describe "when getting a file" do
    @tag :tmp_dir
    test "should create it if it doesn't exist already", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir, todo_file: "todo.txt"}

      Storage.get(storage)

      todos_path = Path.join(tmp_dir, storage.todo_file)

      assert File.exists?(todos_path)
    end

    @tag :tmp_dir
    test "should return it as a TaskList", %{tmp_dir: tmp_dir} do
      storage = %Storage{todo_folder: tmp_dir, todo_file: "todo.txt"}
      task_list = %TaskList{
        tasks: [
          Task.new("do the shopping"),
          Task.new("walk the dog", true),
          Task.new("cook dinner"),
          Task.new("shave")
        ]
      }

      formatted_output = """
      1. do the shopping
      2. walk the dog ✓
      3. cook dinner
      4. shave
      """

      expect(CliFormatterMock, :format, fn ^task_list -> formatted_output end)

      Storage.save(storage, task_list)

      {:ok, result} = Storage.get(storage)

      assert result == task_list
    end
  end
end
