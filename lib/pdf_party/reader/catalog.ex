defmodule PDFParty.Reader.Catalog do
  alias PDFParty.Reader.{
    Document,
    ObjectData,
    Page
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

  @spec pages(Document.t()) :: {:ok, list(%Page{})} | {:error, term()}
  def pages(%Document{xref: %{root: root}} = doc) do
    with {:ok, %{"Pages" => pages_ref}} <- get_catalog_data(root, doc),
         {:ok, %{"Kids" => kids}} <- get_pages_data(pages_ref, doc),
         {:ok, pages} <- load_pages(kids, doc, []) do
      {:ok, pages}
    else
      _ ->
        {:error, :invalid_format}
    end
  end

  defp load_pages([], _doc, pages),
    do: {:ok, pages}

  defp load_pages([{:ref, _, _} = ref | rest], doc, pages) do
    case Document.get_object_data(ref, doc) do
      {:ok, %{"Type" => "Page"}} ->
        with {:ok, page} <- Page.from(ref, doc),
             result <- load_pages(rest, doc, pages ++ [page]) do
          result
        end

      {:ok, %{"Type" => "Pages", "Kids" => kids}} ->
        load_pages(kids ++ rest, doc, pages)

      {:error, _} = error ->
        error
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
