defmodule PDFPartyTest do
  use ExUnit.Case, async: true

  @pdf_file "test/file_fixtures/sample.pdf"
  test "usage" do

    assert {:ok, document} = PDFParty.read(@pdf_file)
    assert {:ok, 2} = PDFParty.pages_count(document)
  end
end
