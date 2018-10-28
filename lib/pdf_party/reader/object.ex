defmodule PDFParty.Reader.Object do
  defstruct id: nil, gen: nil, data: nil

  def new(id, gen) do
    %__MODULE__{id: id, gen: gen}
  end

  def set_data(object, data),
    do: %{object | data: data}

  def get_data(%__MODULE__{data: data}),
    do: {:ok, data}
end
