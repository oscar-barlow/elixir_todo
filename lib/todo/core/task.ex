defmodule Todo.Core.Task do
  @enforce_keys [:id, :description]
  defstruct id: nil, description: nil, is_done: false

  @type t :: %__MODULE__{id: String.t(), description: String.t(), is_done: boolean()}

  def new(description) when is_binary(description) do
    id = :crypto.hash(:sha256, description) |> Base.encode16(case: :lower)
    %__MODULE__{id: id, description: description, is_done: false}
  end
  
  def new(description, is_done) when is_binary(description) do
    id = :crypto.hash(:sha256, description) |> Base.encode16(case: :lower)
    %__MODULE__{id: id, description: description, is_done: is_done}
  end
end
