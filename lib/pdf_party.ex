defmodule PDFParty do
  @moduledoc """
  PDFParty.
  """

  alias PDFParty.Reader.{
    Catalog,
    Document,
  }

  defdelegate read(path, opts \\ []), to: Document
  defdelegate pages(document), to: Catalog
  defdelegate pages_count(document), to: Catalog
end
