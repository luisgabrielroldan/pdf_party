defmodule PDFParty.Reader.Parser do
  @moduledoc """

  Reads objects from a PDF file

  TODO: Validate object start
  TODO: Report file position on error
  """
  alias PDFParty.Reader.{
    Numbers,
    Object,
    Str,
    Tokenizer
  }

  defstruct current: nil, parent: nil, buffer: []

  def parse(io_device, offset \\ nil) do
    try do
      Tokenizer.stream!(io_device, offset)
      |> Stream.transform(%__MODULE__{}, &next_token/2)
      |> Enum.take(1)
      |> Enum.to_list()
      |> load_stream_if_avaliable(io_device)
      |> validate_object_termination(io_device)
      |> case do
        {:error, _} = error ->
          error

        element ->
          {:ok, element}
      end
    catch
      error -> {:error, error}
    end
  end

  defp validate_object_termination(%Object{stream: nil} = object, _),
    do: object

  defp validate_object_termination(%Object{} = object, io_device) do
    io_device
    |> Tokenizer.stream!()
    |> Enum.take(2)
    |> Enum.to_list()
    |> case do
      ["endstream", "endobj"] ->
        object

      _ ->
        throw({:invalid_object_termination, object.id, object.gen})
    end
  end

  defp validate_object_termination(object, _),
    do: object

  defp load_stream_if_avaliable(
         [%Object{stream: :available, dict: %{"Length" => length}} = object],
         io_device
       ) do
    case :file.read(io_device, length) do
      {:ok, stream_data} ->
        Object.set_stream(object, stream_data)

      _ ->
        throw({:invalid_object_stream, object.id, object.gen})
    end
  end

  defp load_stream_if_avaliable([%Object{stream: :available} = obj], _),
    do: throw({:invalid_stream_length, obj.id, obj.gen})

  defp load_stream_if_avaliable([element], _),
    do: element

  # Str (strings)
  defp next_token("(", context),
    do: {[], new_context(context, Str.new())}

  defp next_token(")", %{current: %Str{}, buffer: [value]} = context) do
    context.current
    |> Str.assign(value)
    |> Str.build()
    |> handle_result(context)
  end

  defp next_token("<", context),
    do: {[], new_context(context, Str.new(true))}

  defp next_token(">", %{current: %Str{}, buffer: [value]} = context) do
    context.current
    |> Str.assign(value)
    |> Str.build()
    |> handle_result(context)
  end

  defp next_token(token, %{current: %Str{}} = context) do
    {[], buffer_add(context, token)}
  end

  # Lists
  defp next_token("[", context),
    do: {[], new_context(context, :list)}

  defp next_token("]", %{buffer: buffer, current: :list} = context) do
    buffer
    |> Enum.reverse()
    |> handle_result(context)
  end

  # Dictionaries
  defp next_token("<<", context),
    do: {[], new_context(context, :dictionary)}

  defp next_token(">>", %{buffer: buffer, current: :dictionary} = context) do
    buffer
    |> to_dictionary()
    |> handle_result(context)
  end

  # Name objects
  defp next_token("/", context),
    do: {[], new_context(context, :name)}

  defp next_token(value, %{current: :name} = context) do
    handle_result(value, context)
  end

  # Objects
  defp next_token("obj", %{buffer: [gen, id | _]} = context),
    do: {[], new_context(context, Object.new(id, gen))}

  defp next_token("endobj", %{buffer: [dict], current: %Object{}} = context) do
    context.current
    |> Object.set_dict(dict)
    |> Object.set_stream(nil)
    |> handle_result(context)
  end

  defp next_token("stream", %{buffer: [dict], current: %Object{}} = context) do
    context.current
    |> Object.set_dict(dict)
    |> Object.set_stream(:available)
    |> handle_result(context)
  end

  defp next_token("trailer", context),
    do: {[], new_context(context, :trailer)}

  defp next_token("R", %{buffer: [gen, id | rest]} = context) do
    ref = {:ref, id, gen}

    context = %{context | buffer: [ref | rest]}

    {[], context}
  end

  defp next_token("true", context),
    do: {[], buffer_add(context, true)}

  defp next_token("false", context),
    do: {[], buffer_add(context, false)}

  defp next_token(token, context) do
    value =
      cond do
        Numbers.is_number?(token) ->
          Numbers.parse(token)

        true ->
          throw({:unexpected_token, token})
      end

    {[], buffer_add(context, value)}
  end

  defp handle_result(element, context) do
    context = context.parent

    if is_nil(context.current) do
      # Return the element if there is not parent context
      {[element], context}
    else
      if context.current == :trailer do
        {[element], context}
      else
        # Add element to parent buffer
        context = buffer_add(context, element)
        {[], context}
      end
    end
  end

  def to_dictionary(buffer) do
    buffer
    |> Enum.reverse()
    |> Enum.chunk_every(2)
    |> Enum.map(fn
      [key, value] ->
        {key, value}

      _ ->
        throw({:invalid_dictionary})
    end)
    |> Enum.into(%{})
  end

  def new_context(context, new) do
    %__MODULE__{
      parent: context,
      current: new
    }
  end

  def buffer_add(%__MODULE__{buffer: buffer} = context, value) do
    %{context | buffer: [value | buffer]}
  end
end
