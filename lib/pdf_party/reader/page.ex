defmodule PDFParty.Reader.Page do
  defstruct index: nil, ref: nil, data: nil

  alias PDFParty.Reader.{
    Document,
    Object,
  }

  @spec from(Object.ref(), %Document{}) :: {:ok, %__MODULE__{}} | {:error, term()}
  def from({:ref, _, _} = ref, %Document{} = document) do
    with {:ok, %{"Contents" => contents}} <- Document.get_object_data(ref, document),
         {:ok, data} <- Document.get_object_data(contents, document) do
      {:ok,
       %__MODULE__{
         ref: ref,
         data: data
       }}
    end
  end
end
