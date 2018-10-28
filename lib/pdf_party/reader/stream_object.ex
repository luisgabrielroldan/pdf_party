defmodule PDFParty.Reader.StreamObject do
  alias PDFParty.Reader.{
    Filter,
    Object
  }

  defstruct id: nil, gen: nil, attrs: [], raw_data: nil

  def from(%Object{id: id, gen: gen}),
    do: %__MODULE__{id: id, gen: gen}

  def set_raw_data(%__MODULE__{} = object, raw_data),
    do: %{object | raw_data: raw_data}

  def set_attrs(%__MODULE__{} = object, attrs) when is_map(attrs),
    do: %{object | attrs: attrs}

  def get_data(%__MODULE__{attrs: %{"Filter" => filter}, raw_data: data}),
    do: Filter.apply(data, filter)

  def get_data(%__MODULE__{raw_data: raw_data}),
    do: {:ok, raw_data}
end
