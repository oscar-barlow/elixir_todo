defmodule Todo.Ports do
  alias Todo.Core.TaskList
  defmodule Cli do
    @callback parse(TaskList.t(), String.t()) :: TaskList.t() | :ok
  end

  defmodule CliFormatter do
    @callback format(TaskList.t()) :: String.t()
  end

  defmodule Storage do
    alias Todo.Adapters.Storage

    @callback read(Storage.t()) :: {:ok, TaskList.t()}
    @callback write(Storage.t(), String.t()) :: :ok
  end
end
