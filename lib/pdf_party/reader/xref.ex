defmodule PDFParty.Reader.XRef do
  alias PDFParty.Reader.{
    IOEx,
    XRef.StreamParser,
    XRef.TableParser
  }

  defstruct size: nil, root: nil, info: nil, entries: nil

  @tail_buffer_size 64

  def load(io_device, file_size) do
    with {:ok, offset} <- xref_start(io_device, file_size) do
      :file.position(io_device, offset)

      line = IOEx.read_line(io_device)

      cond do
        line =~ "xref" ->
          TableParser.parse(io_device, offset)

        line =~ "obj" ->
          StreamParser.parse(io_device, offset)

        true ->
          {:error, :xref_invalid_format}
      end
    end
  end

  def xref_start(io_device, file_size) do
    # The last line of the file contains only the end-of-file marker (%%EOF)
    # The two preceding lines contain the keyword startxref and the byte
    # offset from the beginning of the file to the beginning of the xref
    # keyword in the last cross-reference section.
    #
    # So ror now let's look for the startxref on the last 64 bytes at the
    # end of the file :D
    buffer_offset = max(file_size - @tail_buffer_size, 0)

    :file.position(io_device, buffer_offset)

    io_device
    |> IO.binread(:all)
    |> String.split(~r{(\r\n\|\r|\n)})
    |> Enum.map(&String.trim/1)
    |> find_startxref()
  end

  defp find_startxref([]),
    do: {:error, :xref_not_found}

  defp find_startxref(["startxref", xref_start | _]) do
    case Integer.parse(xref_start) do
      {offset, _} -> {:ok, offset}
      _ -> {:error, :xref_not_found}
    end
  end

  defp find_startxref([_ | tail]),
    do: find_startxref(tail)
end
