defmodule PDFParty.Reader.XRef.TableParser do
  @moduledoc """
  XRef Table parser
  """

  alias PDFParty.Reader.{
    IOEx,
    Numbers,
    Parser,
    XRef
  }

  def parse(io_device, start_offset) do
    with {:ok, entries, trailer} <- read_xref_table(start_offset, io_device) do
      document = %XRef{
        entries: entries,
        size: Map.get(trailer, "Size"),
        root: Map.get(trailer, "Root"),
        info: Map.get(trailer, "Info")
      }

      if length(entries) == document.size do
        {:ok, document}
      else
        {:error, :xref_entries_mismatch}
      end
    end
  end

  defp read_xref_table(start_offset, io_device) do
    with {:ok, _} <- :file.position(io_device, start_offset),
         {:skip_token, "xref" <> _} <- {:skip_token, IOEx.read_line(io_device)},
         {:ok, entries} <- read_sections(io_device),
         {:ok, trailer} <- read_trailer(start_offset, io_device) do
      case Map.get(trailer, "Prev") do
        nil ->
          {:ok, entries, trailer}

        prev_xref when is_integer(prev_xref) ->
          with {:ok, prev_entries, _} <- read_xref_table(prev_xref, io_device) do
            {:ok, merge_entries(prev_entries ++ entries), trailer}
          end

        _ ->
          {:error, :xref_invalid_format}
      end
    else
      {:skip_token, _} ->
        {:error, :xref_invalid_format}

      error ->
        error
    end
  end

  defp merge_entries(list, acc \\ %{})

  defp merge_entries([], acc),
    do: Map.values(acc)

  defp merge_entries([{id, _offset, _gen, _state} = entry | rest], acc),
    do: merge_entries(rest, Map.put(acc, id, entry))

  defp read_sections(io_device),
    do: read_sections(io_device, [])

  defp read_sections(io_device, acc) do
    with {:ok, id, length} <- read_section_header(io_device),
         {:ok, entries} <- read_xref_entries(io_device, id, length) do
      read_sections(io_device, acc ++ entries)
    else
      :error ->
        if length(acc) == 0 do
          {:error, :xref_invalid_format}
        else
          {:ok, acc}
        end
    end
  end

  defp read_section_header(io_device) do
    with line when is_binary(line) <- IOEx.read_line(io_device),
         [[id], [length]] <- Regex.scan(~r/[0-9]+/, line) do
      {:ok, Numbers.parse_int!(id), Numbers.parse_int!(length)}
    else
      _ ->
        :error
    end
  end

  defp read_xref_entries(io, id, left, acc \\ [])

  defp read_xref_entries(_io, _id, 0, acc),
    do: {:ok, acc}

  defp read_xref_entries(io_device, id, left, acc) do
    line = IOEx.read_line(io_device)

    case Regex.scan(~r/[0-9fn]+/, line) do
      [[offset], [gen], [state]] ->
        offset = Numbers.parse_int!(offset)
        gen = Numbers.parse_int!(gen)

        state =
          case state do
            "n" -> :n
            _ -> :f
          end

        entry = {id, gen, offset, state}

        read_xref_entries(io_device, id + 1, left - 1, acc ++ [entry])

      _ ->
        {:error, :xref_invalid_format}
    end
  end

  defp read_trailer(start_offset, io_device) do
    :file.position(io_device, start_offset)

    with :ok <- lookup_trailer(io_device),
         {:ok, trailer} when is_map(trailer) <- Parser.parse(io_device) do
      {:ok, trailer}
    end
  end

  defp lookup_trailer(io_device) do
    {:ok, pos} = :file.position(io_device, :cur)

    case IOEx.read_line(io_device) do
      "trailer" ->
        :file.position(io_device, pos)
        :ok

      :eof ->
        {:error, :trailer_not_found}

      _ ->
        lookup_trailer(io_device)
    end
  end
end
