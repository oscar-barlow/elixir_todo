defmodule Todo.Ports do
  alias Todo.Core.TaskList
  defmodule Cli do
    @callback parse(TaskList.t(), String.t()) :: {:ok, String.t()}
  end

  defmodule CliFormatter do
    @callback format(TaskList.t()) :: String.t()
  end

  defmodule Storage do
    @callback read() :: {:ok, TaskList.t()}
    @callback write() :: :ok
  end
end
