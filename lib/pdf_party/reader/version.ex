defmodule PDFParty.Reader.Version do

  alias PDFParty.Reader.IOEx

  def read(io_device) do
    :file.position(io_device, :bof)

    io_device
    |> IOEx.read_line()
    |> parse_version()
  end

  defp parse_version("%PDF-" <> version),
    do: {:ok, String.trim(version)}

  defp parse_version(_),
    do: {:error, :invalid_version}
end
