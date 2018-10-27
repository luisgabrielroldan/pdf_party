defmodule PDFParty.Reader.DocumentTest do
  use ExUnit.Case, async: true

  alias PDFParty.Reader.{
    Document,
    Object
  }

  @pdf_file "test/file_fixtures/pdf_wiki.pdf"
  @texput "test/file_fixtures/texput.pdf"
  @updated_pdf "test/file_fixtures/hello_updated.pdf"

  describe "read/2" do
    test "read document" do
      {:ok, doc} = Document.read(@pdf_file)

      assert %Document{
               objects: objects,
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
      assert length(objects) == 120
      assert length(entries) == 121
    end

    test "read incremental updated document" do
      {:ok, doc} = Document.read(@updated_pdf)

      assert %Document{
               objects: objects,
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
      assert length(objects) == 5
      assert length(entries) == 6
    end

    test "parse file with xref stream" do
      assert {:error, :xref_stream_not_supported} = Document.read(@texput)
    end
  end

  describe "get_object/2" do
    test "with valid reference" do
      {:ok, doc} = Document.read(@pdf_file)

      assert {:ok, obj} = Document.get_object({:ref, 22, 0}, doc)

      assert %Object{
               data: %{
                 "Dests" => {:ref, 120, 0},
                 "Pages" => {:ref, 23, 0},
                 "Type" => "Catalog"
               },
               gen: 0,
               id: 22
             } = obj
    end

    test "with invalid reference" do
      {:ok, doc} = Document.read(@pdf_file)

      assert :error = Document.get_object({:ref, 999, 0}, doc)
    end
  end
end
