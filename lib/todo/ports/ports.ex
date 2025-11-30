defmodule Todo.Ports do
  defmodule Cli do
    alias Todo.Core.TaskList
    @callback parse(TaskList.t(), String.t()) :: TaskList.t() | :ok
  end
  
  # defmodule Storage do
	
  # end
end