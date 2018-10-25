defmodule PDFParty.Reader.XRef do
  alias PDFParty.Reader.{
    Numbers,
    Parser
  }

  defstruct size: nil, root: nil, info: nil, entries: nil

  @tail_buffer_size 64

  def load(io_device, file_size) do
    with {:ok, offset} <- xref_start(io_device, file_size) do
      :file.position(io_device, offset)

      case read_line(io_device) do
        "xref" <> _ ->
          load_xref_table(io_device, offset)

        _ ->
          load_xref_stream(io_device, offset)
      end
    end
  end

  def xref_start(io_device, file_size) do
    # The startxref should be on the last 64 bytes
    # at the end of the file.
    buffer_offset = max(file_size - @tail_buffer_size, 0)

    :file.position(io_device, buffer_offset)

    io_device
    |> IO.binread(:all)
    |> String.split(~r{(\r\n\|\r|\n)})
    |> Enum.map(&String.trim/1)
    |> find_startxref()
  end

  defp read_trailer(io_device, start_offset) do
    :file.position(io_device, start_offset)

    with :ok <- lookup_trailer(io_device),
         {:ok, trailer} when is_map(trailer) <- Parser.parse(io_device) do
      {:ok, trailer}
    end
  end

  defp lookup_trailer(io_device) do
    {:ok, pos} = :file.position(io_device, :cur)

    case read_line(io_device) do
      "trailer" ->
        :file.position(io_device, pos)
        :ok

      :eof ->
        {:error, :trailer_not_found}

      _ ->
        lookup_trailer(io_device)
    end
  end

  defp load_xref_table(io_device, start_offset) do
    with {:ok, entries} <- read_xref_table(io_device),
         {:ok, trailer} <- read_trailer(io_device, start_offset) do

    document =
       %__MODULE__{
         entries: entries,
         size: Map.get(trailer, "Size"),
         root: Map.get(trailer, "Root"),
         info: Map.get(trailer, "Info"),
       }

      if length(entries) == document.size do
        {:ok, document}
      else
        {:error, :xref_entries_mismatch}
      end
    end
  end

  defp read_xref_table(io_device),
    do: read_xref_table(io_device, {:cont, []})

  defp read_xref_table(io_device, {:cont, acc}) do
    with {:ok, _, count} <- read_header(io_device),
         {:ok, entries} <- read_xref_entries(io_device, count) do
      read_xref_table(io_device, {:cont, acc ++ entries})
    else
      {:error, :xref_invalid_header} ->
        read_xref_table(io_device, {:halt, acc})
    end
  end

  defp read_xref_table(_io_device, {:halt, []}),
    do: {:error, :xref_invalid_format}

  defp read_xref_table(_io_device, {:halt, acc}),
    do: {:ok, acc}

  defp read_header(io_device) do
    with line when is_binary(line) <- read_line(io_device),
         [[id], [length]] <- Regex.scan(~r/[0-9]+/, line) do
      {:ok, Numbers.parse_int(id), Numbers.parse_int(length)}
    else
      _ ->
        {:error, :xref_invalid_header}
    end
  end

  defp read_xref_entries(io, left, acc \\ [])

  defp read_xref_entries(_io, 0, acc),
    do: {:ok, acc}

  defp read_xref_entries(io_device, left, acc) do
    line = read_line(io_device)

    case Regex.scan(~r/[0-9fn]+/, line) do
      [[offset], [gen], [state]] ->
        offset = Numbers.parse_int(offset)
        gen = Numbers.parse_int(gen)

        state =
          case state do
            "n" -> :n
            _ -> :f
          end

        entry = {offset, gen, state}

        read_xref_entries(io_device, left - 1, acc ++ [entry])

      _ ->
        {:error, :xref_invalid_format}
    end
  end

  defp load_xref_stream(_io_device, _offset) do
    {:error, :xref_stream_not_supported}
  end

  defp find_startxref([]),
    do: {:error, :xref_start_not_found}

  defp find_startxref(["startxref" | [xref_start | _]]) do
    case Integer.parse(xref_start) do
      {offset, _} -> {:ok, offset}
      _ -> {:error, :xref_start_not_found}
    end
  end

  defp find_startxref([_ | tail]),
    do: find_startxref(tail)

  defp read_line(io_device, buffer \\ "") do
    io_device
    |> IO.binread(1)
    |> case do
      :eof ->
        :eof

      "\r" ->
        read_line(io_device, buffer)

      "\n" ->
        buffer

      c ->
        read_line(io_device, buffer <> c)
    end
  end
end
