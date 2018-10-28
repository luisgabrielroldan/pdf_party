defmodule PDFParty.Reader.Catalog do
  alias PDFParty.Reader.{
    Document,
    ObjectData
  }

  @spec pages_count(Document.t()) :: {:ok, integer()} | {:error, term()}
  def pages_count(%Document{xref: %{root: root}} = doc) do
    with {:ok, root} <- Document.get_object(root, doc),
         {:ok, pages_count} <- fetch_pages_count(root, doc) do
      {:ok, pages_count}
    else
      _ ->
        {:error, :invalid_format}
    end
  end

  defp fetch_pages_count(root, doc) do
    with {:ok, %{"Pages" => pages_ref}} <- ObjectData.from(root),
         {:ok, pages} <- Document.get_object(pages_ref, doc),
         {:ok, %{"Count" => count}} <- ObjectData.from(pages) do
      {:ok, count}
    else
      _ ->
        {:error, :invalid_format}
    end
  end
end
