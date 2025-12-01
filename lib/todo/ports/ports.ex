defmodule Todo.Ports do
  alias Todo.Core.TaskList
  defmodule Cli do
    @callback parse(TaskList.t(), String.t()) :: TaskList.t() | :ok
  end

  defmodule CliFormatter do
    @callback format(TaskList.t()) :: String.t()
  end

  # defmodule Storage do

  # end
end
