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
    @type config :: term()

    @callback get(config) :: {:ok, TaskList.t()} | {:error, :file_error}
    @callback save(config, TaskList.t()) :: :ok | {:error, :write_failed}
  end
end
