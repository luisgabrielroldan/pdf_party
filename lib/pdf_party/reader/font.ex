defmodule PDFParty.Reader.Font do
  defstruct base_font: nil, encoding: nil, subtype: nil, to_unicode: nil, descendants: nil

  alias PDFParty.Reader.{
    Document
  }

  def from({:ref, _, _} = ref, %Document{} = document) do
    with {:ok, %{data: data} =  obj} <- Document.get_object(ref, document),
         :ok <- is_font?(obj) do
      font = %__MODULE__{
        base_font: Map.get(data, "BaseFont"),
        encoding: Map.get(data, "Encoding"),
        subtype: Map.get(data, "Subtype"),
        to_unicode: Map.get(data, "ToUnicode"),
        descendants: Map.get(data, "DescendantFonts", [])
      }

      {:ok, font}
    end
  end

  defp is_font?(%{data: %{"Type" => "Font"}}),
    do: :ok

  defp is_font?(_),
    do: {:error, :invalid_font}
end
