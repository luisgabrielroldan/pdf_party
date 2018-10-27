defmodule PDFParty.Reader.XRefTest do
  use ExUnit.Case

  alias PDFParty.Reader.{
    XRef
  }

  @xref_simple """
  xref
  0 6
  0000000000 65535 f
  0000000100 00000 n
  0000000200 00000 n
  0000000300 00000 n
  0000000400 00000 n
  0000000500 00000 n
  trailer
  <<
  /Size 6
  /Root 1 0 R
  >>
  startxref
  0
  %%EOF
  """

  @xref_update """

  xref
  0 1
  0000000000 65535 f
  5 1
  0000000666 00000 n
  trailer
  <<
  /Size 6
  /Root 1 0 R
  /Prev 0
  >>
  startxref
  176
  %%EOF
  """

  describe "xref_start/2" do
    test "look for last xref table" do
      {io_device, size} = from_string(@xref_simple)

      assert {:ok, 0} = XRef.xref_start(io_device, size)
    end

    test "look for last xref table on updated doc" do
      {io_device, size} = from_string(@xref_simple <> @xref_update)

      assert {:ok, 176} = XRef.xref_start(io_device, size)
    end
  end

  describe "load/2" do
    test "single xref table" do
      {io_device, size} = from_string(@xref_simple)

      assert {:ok,
              %XRef{
                entries: entries,
                root: {:ref, 1, 0},
                size: 6
              }} = XRef.load(io_device, size)

      assert entries == [
               {0, 65535, 0, :f},
               {1, 0, 100, :n},
               {2, 0, 200, :n},
               {3, 0, 300, :n},
               {4, 0, 400, :n},
               {5, 0, 500, :n}
             ]
    end

    test "updated references" do
      {io_device, size} = from_string(@xref_simple <> @xref_update)

      assert {:ok,
              %XRef{
                entries: entries,
                root: {:ref, 1, 0},
                size: 6
              }} = XRef.load(io_device, size)

      assert entries == [
               {0, 65535, 0, :f},
               {1, 0, 100, :n},
               {2, 0, 200, :n},
               {3, 0, 300, :n},
               {4, 0, 400, :n},
               {5, 0, 666, :n}
             ]
    end
  end

  defp from_string(doc) do
    {:ok, io_device} = File.open(doc, [:ram])
    size = String.length(doc)

    {io_device, size}
  end
end
