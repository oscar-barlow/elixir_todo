defmodule Todo.Core.Task do
  @enforce_keys [:description]
  defstruct description: nil, is_done: false

  @type t :: %__MODULE__{description: String.t(), is_done: boolean()}
end
