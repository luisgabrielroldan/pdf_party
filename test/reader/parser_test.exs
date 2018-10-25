defmodule PDFParty.Reader.ParserTest do
  use ExUnit.Case

  alias PDFParty.Reader.{
    Parser,
    Object,
  }

  @object_data """
  % Simple comment
  1 0 obj
  <<
      /Names    [
        (Apple)   (Orange)      % These are sorted, hence A, N, Z...
        (Name 1)  1             % and values can be any type
        (Name 2)  /Value2
        (Zebra)   << /A /B >>
      ]
      /Foo        << /Boolean true /Int 1234567890 >>
      /Reals      [ 0.0 -0.01 -100.123456789 ]
      /Reference  4 0 R
      /Int  0000234
  >>
  endobj

  2 0 obj
  << >>
  endobj
  """

  @stream_object """
  % Simple comment
  2 0 obj
  <<
      /Length   3
  >>
  stream
  Foo
  endstream
  endobj

  3 0 obj
  << >>
  endobj
  """

  describe "read_object/2" do
    test "read simple object" do
      assert parse(@object_data) == %Object{
               dict: %{
                 "Foo" => %{"Boolean" => true, "Int" => 1_234_567_890},
                 "Names" => [
                   "Apple",
                   "Orange",
                   "Name 1",
                   1,
                   "Name 2",
                   "Value2",
                   "Zebra",
                   %{"A" => "B"}
                 ],
                 "Reals" => [0.0, -0.01, -100.123456789],
                 "Reference" => {:ref, 4, 0},
                 "Int" => 234
               },
               gen: 0,
               id: 1,
               stream: nil
             }
    end

    test "read stream object" do
      assert parse(@stream_object) == %Object{
        dict: %{"Length" => 3},
        gen: 0,
        id: 2,
        stream: "Foo"
      }
    end
  end

  defp parse(str) do
    {:ok, io} = File.open(str, [:ram])

    Parser.parse_object!(io, 0)
  end
end
