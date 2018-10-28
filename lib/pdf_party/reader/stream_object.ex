defmodule PDFParty.Reader.StreamObject do
  alias PDFParty.Reader.Object

  defstruct id: nil, gen: nil, attrs: [], raw_data: nil

  def from(%Object{id: id, gen: gen}) do
    %__MODULE__{id: id, gen: gen}
  end

  def set_raw_data(%__MODULE__{} = object, raw_data),
    do: %{object | raw_data: raw_data}

  def set_attrs(%__MODULE__{} = object, attrs) when is_map(attrs),
    do: %{object | attrs: attrs}

  def get_data(%__MODULE__{attrs: %{"Filter" => "FlateDecode"}, raw_data: raw_data}) do
    inflate(raw_data)
  end

  def get_data(%__MODULE__{raw_data: raw_data}) do
    # TODO: Apply filters
    {:ok, raw_data}
  end

  def inflate(raw_data) do
    z = :zlib.open()
    :zlib.inflateInit(z)
    result = inflate(z, [], :zlib.safeInflate(z, raw_data))
    :zlib.close(z)

    result
  end

  def inflate(z, acc, {:continue, decomp}),
    do: inflate(z, acc ++ decomp, :zlib.safeInflate(z, []))

  def inflate(z, acc, {:finished, decomp}) do
    :zlib.inflateEnd(z)
    {:ok, to_string(acc ++ decomp)}
  end
end
