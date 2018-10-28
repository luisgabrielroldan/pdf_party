defmodule PDFParty.Reader.StreamObject do

  alias  PDFParty.Reader.Object

  defstruct id: nil, gen: nil, attrs: [], raw_data: nil

  def from(%Object{id: id, gen: gen}) do
    %__MODULE__{id: id, gen: gen}
  end

  def set_raw_data(%__MODULE__{} = object, raw_data),
    do: %{object | raw_data: raw_data}

  def set_attrs(%__MODULE__{} = object, attrs) when is_map(attrs),
    do: %{object | attrs: attrs}

  def get_data(%__MODULE__{raw_data: raw_data}) do
    # TODO: Apply filters
    raw_data
  end
end
