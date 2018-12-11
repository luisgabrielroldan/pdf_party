defmodule PDFParty.Reader.XRef.StreamParser do
  @moduledoc """
  XRef Stream parser
  """

  def parse(_io_device, _stream_offset),
    do: {:error, :xref_stream_not_supported}
end
