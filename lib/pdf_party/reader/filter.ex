defmodule PDFParty.Reader.Filter do
  alias PDFParty.Reader.Filter.{
    Flate
  }

  @callback filter(iodata()) :: {:ok, iodata()} | {:error, term()}

  @spec apply(iodata(), String.t()) :: {:ok, iodata()} | {:error, term()}
  def apply(data, "FlateDecode"),
    do: Flate.filter(data)

  def apply(_data, _),
    do: {:error, :unsupported_filter}
end
