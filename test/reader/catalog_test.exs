defmodule PDFParty.Reader.CatalogTest do
  use ExUnit.Case, async: true

  alias PDFParty.Reader.{
    Document,
    Catalog
  }

  @pdf_1 "test/file_fixtures/sample.pdf"
  @pdf_2 "test/file_fixtures/pdf_wiki.pdf"

  describe "pages_count/1" do
    test "read document" do
      {:ok, doc_1} = Document.read(@pdf_1)
      assert {:ok, 2} = Catalog.pages_count(doc_1)

      {:ok, doc_2} = Document.read(@pdf_2)
      assert {:ok, 18} = Catalog.pages_count(doc_2)
    end
  end
end
