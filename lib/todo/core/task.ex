defmodule Todo.Core.Task do
  @enforce_keys [:id, :description]
  defstruct id: nil, description: nil, is_done: false

  @type t :: %__MODULE__{id: String.t(), description: String.t(), is_done: boolean()}

  defp generate_id(description) when is_binary(description) do
    :crypto.hash(:sha256, description) |> Base.encode16(case: :lower)
  end

  def new(description) when is_binary(description) do
    id = generate_id(description)
    %__MODULE__{id: id, description: description, is_done: false}
  end
  
  def new(description, is_done) when is_binary(description) do
    id = generate_id(description)
    %__MODULE__{id: id, description: description, is_done: is_done}
  end
end
