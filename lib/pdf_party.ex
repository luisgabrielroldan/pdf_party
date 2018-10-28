defmodule PDFParty do
  @moduledoc """
  PDFParty.
  """

  alias PDFParty.Reader.{
    Catalog,
    Document,
    Page
  }

  defdelegate read(path, opts \\ []), to: Document
  defdelegate pages(document), to: Catalog
  defdelegate pages_count(document), to: Catalog

  def text(%Page{} = page),
    do: Page.text(page)
end
