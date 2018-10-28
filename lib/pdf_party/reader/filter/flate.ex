defmodule PDFParty.Reader.Filter.Flate do
  @moduledoc """
  Implement Flate decode
  """

  @behaviour PDFParty.Reader.Filter

  def filter(raw_data),
    do: inflate(raw_data)

  defp inflate(data) do
    z = :zlib.open()

    :zlib.inflateInit(z)

    result = inflate(z, [], :zlib.safeInflate(z, data))

    :zlib.close(z)

    result
  end

  defp inflate(z, acc, {:continue, decomp}),
    do: inflate(z, acc ++ decomp, :zlib.safeInflate(z, []))

  defp inflate(z, acc, {:finished, decomp}) do
    :zlib.inflateEnd(z)
    {:ok, to_string(acc ++ decomp)}
  end
end
