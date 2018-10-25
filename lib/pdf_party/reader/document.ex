defmodule PDFParty.Reader.Document do
  alias PDFParty.Reader.{
    Parser,
    Version,
    XRef
  }

  defstruct version: nil, xref_table: nil, cache: nil, path: nil

  @file_opts [:read, :raw, :read_ahead]

  def read(path, opts \\ []) do
    opts = Enum.into(opts, %{})
    path = Path.absname(path)

    with {:ok, %{size: file_size}} <- File.stat(path),
         {:ok, io_device} <- File.open(path, @file_opts),
         {:ok, version} <- Version.read(io_device),
         {:ok, xref_table} <- XRef.load(io_device, file_size),
         {:ok, cache} <- preload_objects(io_device, xref_table, opts) do
      document = %__MODULE__{
        version: version,
        xref_table: xref_table,
        cache: cache,
        path: path
      }

      {:ok, document}
    end
  end

  defp preload_objects(io_device, %{entries: entries}, %{preload: true}),
    do: load_objects(entries, io_device, [])

  defp preload_objects(_io_device, _xref_table, _opts),
    do: {:ok, nil}

  defp load_objects([], _io_device, acc),
    do: {:ok, acc}

  defp load_objects([{offset, _, :n} | rest], io_device, acc) do
    case Parser.parse(io_device, offset) do
      {:ok, obj} when is_map(obj) ->
        load_objects(rest, io_device, acc++[obj])
      {:error, error} ->
        {:error, :parse_objects, offset, error}
    end
  end

  defp load_objects([_ | rest], io_device, acc),
    do: load_objects(rest, io_device, acc)
end
