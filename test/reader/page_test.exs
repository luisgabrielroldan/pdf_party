defmodule PDFParty.Reader.PageTest do
  use ExUnit.Case, async: true

  alias PDFParty.Reader.{
    Catalog,
    Document,
    Font
  }

  @pdf_1 "test/file_fixtures/pdf_wiki.pdf"

  describe "pages/1" do
    test "read pages" do
      {:ok, doc} = Document.read(@pdf_1)
      assert {:ok, [page_1 | _]} = Catalog.pages(doc)

      assert %{
               resources: %{
                 "F0" => %Font{base_font: "DejaVuSans", subtype: "Type0", encoding: "Identity-H"},
                 "F1" => %Font{
                   base_font: "LiberationSans-Bold",
                   subtype: "Type0",
                   encoding: "Identity-H"
                 },
                 "F2" => %Font{
                   base_font: "LiberationSans",
                   subtype: "Type0",
                   encoding: "Identity-H"
                 },
                 "F3" => %Font{base_font: nil, subtype: "Type3", encoding: %{}},
                 "F4" => %Font{
                   base_font: "LiberationSerif-Bold",
                   subtype: "Type0",
                   encoding: "Identity-H"
                 },
                 "F5" => %Font{
                   base_font: "LiberationSerif",
                   subtype: "Type0",
                   encoding: "Identity-H"
                 }
               }
             } = page_1
    end
  end
end
