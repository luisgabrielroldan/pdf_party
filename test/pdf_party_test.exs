defmodule PDFPartyTest do
  use ExUnit.Case, async: true

  @pdf_file_1 "test/file_fixtures/hello_updated.pdf"
  @pdf_file_2 "test/file_fixtures/sample.pdf"

  test "usage 1" do
    assert {:ok, document} = PDFParty.read(@pdf_file_1)
    assert {:ok, 1} = PDFParty.pages_count(document)
    assert {:ok, [page]} = PDFParty.pages(document)

    assert PDFParty.text(page) =~ "Hello, boy!"
  end

  test "usage 2" do
    assert {:ok, document} = PDFParty.read(@pdf_file_2)
    assert {:ok, 2} = PDFParty.pages_count(document)
    assert {:ok, [page_1, page_2]} = PDFParty.pages(document)

    assert PDFParty.text(page_1) =~ "This is a small demonstration .pdf file"
    assert PDFParty.text(page_2) =~ "Yet more text. And more text."
  end
end
