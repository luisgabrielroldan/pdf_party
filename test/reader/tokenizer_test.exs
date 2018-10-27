defmodule PDFParty.Reader.TokenizerTest do
  use ExUnit.Case

  alias PDFParty.Reader.Tokenizer

  @name_tree """
  % Simple comment
  1 0 obj
  <<
      /Names    [
        (Apple)   (Orange)      % These are sorted, hence A, N, Z...
        (Name 1)  1             % and values can be any type
        (Name 2)  /Value2
        (Zebra)   << /A /B >>
      ]
  >>
  endobj
  """

  describe "stream!/2" do
    test "ignore comments" do
      assert tokenize!("a % comment\r\nb % comment\r\n") == ["a", "b"]
      assert tokenize!("a % comment\nb % comment\n") == ["a", "b"]
      assert tokenize!("a b % comment") == ["a", "b"]
      assert tokenize!("a b % comment\r\n") == ["a", "b"]
    end

    test "string objects" do
      assert tokenize!("(Hello)") == ["(", "Hello", ")"]
      assert tokenize!("(Hello World)") == ["(", "Hello World", ")"]
      assert tokenize!("(Hello \\(World\\))") == ["(", "Hello \\(World\\)", ")"]
      assert tokenize!("(Hello \\World)") == ["(", "Hello \\World", ")"]
      assert tokenize!("(Hello (World))") == ["(", "Hello (World)", ")"]
      assert tokenize!("(Hello (\\))") == ["(", "Hello (\\)", ")"]
      assert tokenize!("(Hello (\\123(())))") == ["(", "Hello (\\123(()))", ")"]

      # Hex strings
      assert tokenize!("<FFFE0040>") == ["<", "FFFE0040", ">"]
      assert tokenize!("<1C 2D 3F>") == ["<", "1C2D3F", ">"]

      assert tokenize!("<01 23 45 67 89 AB CD EF ab cd ef>") ==
               ["<", "0123456789ABCDEFabcdef", ">"]
    end

    test "name objects" do
      assert tokenize!("/K#20L /Abc") == ["/", "K#20L", "/", "Abc"]
    end

    test "array objects" do
      assert tokenize!("[ 0 0 612 792 ]") == ["[", "0", "0", "612", "792", "]"]
      assert tokenize!("[ 0 [0 612] 792 ]") == ["[", "0", "[", "0", "612", "]", "792", "]"]
      assert tokenize!("[(T) -20.5 (H)]") == ["[", "(", "T", ")", "-20.5", "(", "H", ")", "]"]
    end

    test "dictionaries" do
      assert tokenize!("<< /K /V >>") == ["<<", "/", "K", "/", "V", ">>"]

      # Stripped dictionary
      assert tokenize!("<</Length 42/K/V>>") ==
               ["<<", "/", "Length", "42", "/", "K", "/", "V", ">>"]
    end

    test "name tree" do
      assert tokenize!(@name_tree) ==
               ["1", "0", "obj", "<<", "/", "Names", "[", "("] ++
                 ["Apple", ")", "(", "Orange", ")", "(", "Name 1", ")"] ++
                 ["1", "(", "Name 2", ")", "/", "Value2", "(", "Zebra"] ++
                 [")", "<<", "/", "A", "/", "B", ">>", "]", ">>", "endobj"]
    end
  end

  defp tokenize!(str) do
    {:ok, io} = File.open(str, [:ram])

    io
    |> Tokenizer.stream!(0)
    |> Enum.to_list()
  end
end
