defmodule PDFParty.Reader.DocumentTest do
  use ExUnit.Case

  alias PDFParty.Reader.Document

  @pdf_file "test/file_fixtures/pdf_wiki.pdf"
  @texput "test/file_fixtures/texput.pdf"
  @updated_pdf "test/file_fixtures/hello_updated.pdf"

  describe "read/2" do
    test "read without preload" do
      {:ok, doc} = Document.read(@pdf_file, preload: false)

      assert %Document{
               cache: nil,
               version: "1.4",
               path: path,
               xref_table: %{
                 entries: entries,
                 info: {:ref, 1, 0},
                 root: {:ref, 22, 0},
                 size: 121
               }
             } = doc

      assert path =~ @pdf_file
      assert length(entries) == 121
    end

    test "read with preload" do
      {:ok, doc} = Document.read(@pdf_file, preload: true)

      assert %Document{
               cache: cache,
               version: "1.4",
               path: path,
               xref_table: %{
                 entries: entries,
                 info: {:ref, 1, 0},
                 root: {:ref, 22, 0},
                 size: 121
               }
             } = doc

      assert path =~ @pdf_file
      assert length(cache) == 120
      assert length(entries) == 121
    end

    test "read incremental updated document" do
      {:ok, doc} = Document.read(@updated_pdf, preload: true)

      assert %Document{
               cache: cache,
               version: "1.7",
               path: path,
               xref_table: %{
                 entries: entries,
                 info: nil,
                 root: {:ref, 1, 0},
                 size: 6
               }
             } = doc

      assert path =~ @updated_pdf
      assert length(cache) == 5
      assert length(entries) == 6
    end
  end

  test "parse file with xref stream" do
    assert {:error, :xref_stream_not_supported} = Document.read(@texput)
  end
end
