defmodule Todo.Ports do
  alias Todo.Core.TaskList

  defmodule Cli do
    @callback parse(TaskList.t(), {keyword(), String.t()}) ::
                {:ok, TaskList.t(), String.t()} | {:ok, String.t()}
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
