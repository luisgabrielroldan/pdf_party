defmodule PDFParty.Reader.Page do
  defstruct index: nil, ref: nil, data: nil, page_attrs: nil, resources: nil

  alias PDFParty.Reader.{
    Document,
    Font,
    Object,
    ObjectData,
    Parser
  }

  @spec from(Object.ref(), %Document{}) :: {:ok, %__MODULE__{}} | {:error, term()}
  def from({:ref, _, _} = ref, %Document{} = document) do
    with {:ok, %{"Contents" => contents} = page_attrs} <- Document.get_object_data(ref, document),
         {:ok, content} <- Document.get_object(contents, document),
         {:ok, resources} <- get_resources(page_attrs, document),
         {:ok, data} <- ObjectData.from(content) do
      {:ok,
       %__MODULE__{
         ref: ref,
         page_attrs: page_attrs,
         data: data,
         resources: resources
       }}
    end
  end

  def text(%__MODULE__{data: data}) do
    with {:ok, text} <- Parser.parse(data, nil, all: true) do
      filter_text(text)
    else
      _ ->
        nil
    end
  end

  defp get_resources(%{"Resources" => %{"Font" => fonts}}, document) do
    resources =
      fonts
      |> Enum.into([])
      |> Enum.reduce_while([], fn {name, ref}, acc ->
        case Font.from(ref, document) do
          {:ok, font} ->
            {:cont, acc ++ [{name, font}]}

          error ->
            {:halt, error}
        end
      end)

    case resources do
      {:error, _} = error ->
        error

      resources ->
        {:ok, Enum.into(resources, %{})}
    end
  end

  defp get_resources(_, document),
    do: {:ok, []}

  defp filter_text(list, acc \\ "")

  defp filter_text([], acc),
    do: acc

  defp filter_text([{:text, list} | rest], acc) do
    acc = acc <> filter_text(list)

    filter_text(rest, acc)
  end

  defp filter_text([e | rest], acc) do
    acc = acc <> filter_text(e)

    filter_text(rest, acc)
  end

  defp filter_text(e, acc) when is_binary(e),
    do: acc <> e

  defp filter_text(_, acc),
    do: acc
end
