# pdf_party

**This library is work in progress, it's in a pre-alpha state**

pdf_party :confetti_ball: provides access to the content of a PDF file through a friendly Elixir API.

The short term goal of the library is to provide a basic PDF parser implemented in Elixir that enable developers to test PDF documents with ex_unit.

## Usage

```elixir
  test "usage example" do
    assert {:ok, document} = PDFParty.read("file.pdf")
    assert {:ok, 2} = PDFParty.pages_count(document)
    assert {:ok, [page_1, page_2]} = PDFParty.pages(document)

    assert PDFParty.text(page_1) =~ "This text is in the first page"
    assert PDFParty.text(page_2) =~ "This text is in the second page"
  end
```

## Documentation

Documentation can be found [here](https://hexdocs.pm/pdf_party)

## Installation

*Note that the library is not published yet!*

```elixir
def deps do
  [
    {:pdf_party, "~> 1.0.0"}
  ]
end
```

## Dialyzer

This project uses Dialyzer static analysis tool.

```
mix dialyzer
```

## License

pdf_party is licensed under the MIT license.

See [LICENSE](./LICENSE) for the full license text.
