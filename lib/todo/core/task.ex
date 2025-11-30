defmodule Todo.Core.Task do
  defstruct description: "", is_done: false
  
  @type t :: %__MODULE__{description: String.t(), is_done: boolean()}
end
