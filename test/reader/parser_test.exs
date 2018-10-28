defmodule PDFParty.Reader.ParserTest do
  use ExUnit.Case, async: true

  alias PDFParty.Reader.{
    Parser,
    Object,
    StreamObject
  }

  @many_objects_data """
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

  @dictionary_object """
  3 0 obj
  <<
    /Foo 1
    /Bar (A)
    /Baz 1 0 R
    /Coz [<48656C6C6F20776F726C64> <40204>]
  >>
  endobj
  """

  @string_object """
  3 0 obj
  (Hey hey Captain!)
  endobj
  """

  @stream_object """
  2 0 obj
  <<
    /Length 44
  >>
  stream
  BT
  70 50 TD
  /F1 12 Tf
  (Hello, world!) Tj
  ET
  endstream
  endobj
  """

  describe "read_object/2" do
    test "read only first object found" do
      assert parse(@many_objects_data) ==
               {:ok,
                %Object{
                  data: %{
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
                  id: 1
                }}
    end

    test "read dictionary object" do
      assert parse(@dictionary_object) ==
               {:ok,
                %Object{
                  data: %{
                    "Foo" => 1,
                    "Bar" => "A",
                    "Baz" => {:ref, 1, 0},
                    "Coz" => ["Hello world", "@ @"]
                  },
                  gen: 0,
                  id: 3
                }}
    end

    test "read string object" do
      assert parse(@string_object) ==
               {:ok,
                %Object{
                  data: "Hey hey Captain!",
                  gen: 0,
                  id: 3
                }}
    end

    test "read stream object" do
      assert {:ok,
              %StreamObject{
                attrs: %{"Length" => 44},
                gen: 0,
                id: 2,
                raw_data: raw_data
              }} = parse(@stream_object)

      assert """
             BT
             70 50 TD
             /F1 12 Tf
             (Hello, world!) Tj
             ET
             """ == raw_data
    end
  end

  defp parse(str) do
    {:ok, io} = File.open(str, [:ram])

    Parser.parse(io, 0)
  end
end
