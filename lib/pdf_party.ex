defmodule PDFParty do
  @moduledoc """
  PDFParty.
  """

  alias PDFParty.Reader.Document

  defdelegate read(path, opts \\ []), to: Document
  defdelegate pages_count(document), to: Document
end
