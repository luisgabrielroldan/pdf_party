defmodule PDFParty.Reader.Catalog do
  alias PDFParty.Reader.{
    Document,
    ObjectData
  }

  @spec pages_count(Document.t()) :: {:ok, integer()} | {:error, term()}
  def pages_count(%Document{xref: %{root: root}} = doc) do
    with {:ok, %{"Pages" => pages}} <- get_catalog_data(root, doc),
         {:ok, %{"Count" => count}} <- get_pages_data(pages, doc) do
      {:ok, count}
    else
      _ ->
        {:error, :invalid_format}
    end
  end

  defp get_catalog_data(ref, doc) do
    with {:ok, catalog} <- Document.get_object(ref, doc),
         {:ok, data} <- ObjectData.from(catalog) do
      {:ok, data}
    end
  end

  defp get_pages_data(ref, doc) do
    with {:ok, pages} <- Document.get_object(ref, doc),
         {:ok, data} <- ObjectData.from(pages) do
      {:ok, data}
    end
  end
end
