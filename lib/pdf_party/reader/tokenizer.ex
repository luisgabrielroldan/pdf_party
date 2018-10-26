defmodule PDFParty.Reader.Tokenizer do
  @moduledoc """
  PDF Tokenizer

  Context fields:

  * `io_device`     - opened file handler
  * `last_token`    - the last token send the emited
  * `buffer`        - characters buffer
  * `depth`         - used to detect nested parentesis inside strings
  * `next`          - if not nil, the next iteration will use that value instead of read a next character
  """
  
  defstruct io_device: nil, last_token: nil, buffer: nil, depth: nil, next: nil

  @typep t :: %__MODULE__{
    io_device: File.io_device(),
    last_token: String.t(),
    buffer: String.t(),
    depth: integer()
  }

  @token_whitespace [<<0x00>>, <<0x09>>, <<0x0A>>, <<0x0C>>, <<0x0D>>, <<0x20>>]
  @opening_delimiter ["[", "{"]
  @closing_delimiter ["]", "}"]
  @opening_closing_delimiter @opening_delimiter ++ @closing_delimiter

  @doc """
  Emits a secuence of tokens for the given device and offset.
  """
  @spec stream!(io_device :: File.io_device(), offset :: integer()) :: Enumerable.t()
  def stream!(io_device, offset \\ nil) do

    if not is_nil(offset) do
      :file.position(io_device, offset)
    end

    context = %__MODULE__{
      io_device: io_device,
      last_token: nil,
      buffer: ""
    }

    Stream.resource(
      fn -> context end,
      &next_token/1,
      fn _ -> nil end
    )
  end

  defp next_token(%__MODULE__{} = context) do
    context
    |> read_byte!()
    |> process_byte()
  end

  # =====================================================

  @spec process_byte({<<_::8>>, __MODULE__.t()}) ::
    {list(), t()} | {:halt, t()}
  
  defp process_byte({_, %{last_token: :eof} = context}),
    do: {:halt, context}

  # =====================================================
  # Inside a comment
  # =====================================================
  defp process_byte({byte, %{last_token: "%"} = context})
       when byte in [:eof, <<0x0A>>, <<0x0D>>] do
    # When the comment ends, just clean the token buffer and switch
    # to regular mode
    context =
      context
      |> set_buffer("")
      |> set_last_token("")

    context
    |> read_byte!()
    |> process_byte()
  end

  defp process_byte({_, %{last_token: "%"} = context}) do
    context
    |> read_byte!()
    |> process_byte()
  end

  # =====================================================
  # Inside an hex string
  # =====================================================
  defp process_byte({:eof, %{last_token: "<", buffer: buffer} = context}) do
    if String.length(buffer) > 0 do
      context
      |> set_last_token(:eof)
      |> return_token()
    else
      {:halt, context}
    end
  end

  defp process_byte({">", %{last_token: "<", buffer: buffer} = context}) do
    if String.length(buffer) > 0 do
      return_token(context, [">"])
    else
      context
      |> set_buffer(">")
      |> return_token()
    end
  end

  defp process_byte({byte, %{last_token: "<", buffer: buffer} = context}) do
    buffer =
      if hex_digit?(byte) do
        buffer <> byte
      else
        buffer
      end

    context
    |> set_buffer(buffer)
    |> read_byte!()
    |> process_byte()
  end

  # =====================================================
  # Inside a literal 
  # =====================================================
  defp process_byte({:eof, %{last_token: "(", buffer: buffer} = context}) do
    if String.length(buffer) > 0 do
      context
      |> set_last_token(:eof)
      |> return_token()
    else
      {:halt, context}
    end
  end

  defp process_byte({")", %{last_token: "(", buffer: buffer, depth: 1} = context}) do
    if String.length(buffer) > 0 do
      # If the previous was an escape char, continue parsing the literal
      if String.last(buffer) == "\\" do
        context
        |> set_buffer(buffer <> ")")
        |> read_byte!()
        |> process_byte()
      else
        return_token(context, [")"])
      end
    else
      context
      |> set_buffer(")")
      |> return_token()
    end
  end

  # Save all chars to token buffer
  defp process_byte({byte, %{last_token: "(", buffer: buffer, depth: depth} = context}) do
    depth =
      case byte do
        "(" -> depth + 1
        ")" -> depth - 1
        _ -> depth
      end

    context
    |> set_buffer(buffer <> byte)
    |> set_depth(depth)
    |> read_byte!()
    |> process_byte()
  end

  # =====================================================
  # Regular state
  # =====================================================
  defp process_byte({:eof, %{buffer: buffer} = context}) do
    if String.length(buffer) > 0 do
      context
      |> set_last_token(:eof)
      |> return_token()
    else
      {:halt, context}
    end
  end

  defp process_byte({"/", %{buffer: buffer} = context}) do
    if String.length(buffer) > 0 do
      return_token(context, ["/"])
    else
      context =
        context
        |> set_buffer("")
        |> set_last_token("/")

      {["/"], context}
    end
  end

  defp process_byte({"<", %{buffer: buffer} = context}) do
    {next_byte, context} = read_byte!(context)

    {new_token, context} =
      cond do
        next_byte == "<" ->
          {"<<", context}

        true ->
          {"<", set_next(context, next_byte)}
      end

    if String.length(buffer) > 0 do
      return_token(context, [new_token])
    else
      context
      |> set_buffer(new_token)
      |> return_token()
    end
  end

  defp process_byte({">", %{buffer: buffer} = context}) do
    {next_byte, context} = read_byte!(context)

    {new_token, context} =
      cond do
        next_byte == ">" ->
          {">>", context}

        true ->
          {">", set_next(context, next_byte)}
      end

    if String.length(buffer) > 0 do
      return_token(context, [new_token])
    else
      context
      |> set_buffer(new_token)
      |> return_token()
    end
  end

  defp process_byte({"(", %{buffer: buffer} = context}) do
    context = %{context | depth: 1}

    if String.length(buffer) > 0 do
      return_token(context, ["("])
    else
      context
      |> set_buffer("(")
      |> return_token()
    end
  end

  # Comment started
  defp process_byte({"%", %{buffer: buffer} = context}) do
    context = set_last_token(context, "%")

    if String.length(buffer) > 0 do
      return_token(context)
    else
      context
      |> read_byte!()
      |> process_byte()
    end
  end

  defp process_byte({byte, %{buffer: buffer} = context})
       when byte in @opening_closing_delimiter do
    if String.length(buffer) > 0 do
      return_token(context, [byte])
    else
      context
      |> set_buffer(byte)
      |> return_token()
    end
  end

  defp process_byte({byte, %{buffer: buffer} = context})
       when byte in @token_whitespace do
    if String.length(buffer) > 0 do
      return_token(context)
    else
      context
      |> read_byte!()
      |> process_byte()
    end
  end

  # Append chars to token buffer
  defp process_byte({byte, %{buffer: buffer} = context}) do
    context
    |> set_buffer(buffer <> byte)
    |> read_byte!()
    |> process_byte()
  end

  # =====================================================

  defp set_buffer(context, buffer),
    do: %{context | buffer: buffer}

  defp set_next(context, next),
    do: %{context | next: next}

  defp set_depth(context, depth),
    do: %{context | depth: depth}

  defp set_last_token(context, buffer),
    do: %{context | last_token: buffer}

  defp return_token(%{buffer: buffer} = context, extra_tokens \\ []) do
    tokens = [buffer] ++ extra_tokens

    context =
      context
      |> set_buffer("")
      |> set_last_token(List.last(tokens))

    {tokens, context}
  end

  defp read_byte!(%{next: nil} = context),
    do: {read!(context, 1), context}

  defp read_byte!(%{next: next} = context),
    do: {next, set_next(context, nil)}

  def read!(%{io_device: io_device}, bytes) do
    case IO.binread(io_device, bytes) do
      :eof ->
        :eof

      {:error, _} = error ->
        throw {:read_error, error}

      data ->
        data
    end
  end

  defp hex_digit?(<<byte>>) when 0x30 <= byte and byte <= 0x39,
    do: true
  defp hex_digit?(<<byte>>) when 0x41 <= byte and byte <= 0x46,
    do: true
  defp hex_digit?(<<byte>>) when 0x61 <= byte and byte <= 0x66,
      do: true
  defp hex_digit?(<<byte>>), do: false
end
