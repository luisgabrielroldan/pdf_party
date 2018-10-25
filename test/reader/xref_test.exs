defmodule PDFParty.Reader.XRefTest do
  use ExUnit.Case

  alias PDFParty.Reader.{
    XRef
  }

  @xref_sample """
  xref
  0 1
  0000000000 65535 f
  4 2
  0000000100 00000 n
  0000000200 00000 n
  10 2
  0000000300 00000 n
  0000000400 00000 n
  trailer
  <<
    /Size 5
    /Root 1 0 R
    /Info 1 0 R
  >>
  startxref
  0
  %%EOF
  """

  test "xref_start/2" do
    {:ok, io_device} = File.open(@xref_sample, [:ram])
    size = String.length(@xref_sample)

    assert {:ok, 0} = XRef.xref_start(io_device, size)
  end

  test "load/2" do
    {:ok, io_device} = File.open(@xref_sample, [:ram])
    size = String.length(@xref_sample)

    assert {:ok,
            %XRef{
              entries: [
                {0, 65535, :f},
                {100, 0, :n},
                {200, 0, :n},
                {300, 0, :n},
                {400, 0, :n}
              ],
              info: {:ref, 1, 0},
              root: {:ref, 1, 0},
              size: 5
            }} = XRef.load(io_device, size)
  end
end
