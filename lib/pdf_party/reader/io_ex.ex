defmodule PDFParty.Reader.IOEx do
  def read_line(io_device, buffer \\ "") do
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
