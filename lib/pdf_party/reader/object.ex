defmodule PDFParty.Reader.Object do
  defstruct id: nil, gen: nil, dict: [], stream: nil

  def new(id, gen) do
    %__MODULE__{id: id, gen: gen}
  end

  def set_stream(object, stream),
    do: %{object | stream: stream}

  def set_dict(object, dict) when is_map(dict),
    do: %{object | dict: dict}
end
