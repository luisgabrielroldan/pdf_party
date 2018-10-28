alias PDFParty.Reader.{
  Object,
  StreamObject,
  ObjectData
}

defprotocol ObjectData do
  @dialyzer {:nowarn_function, __protocol__: 1}
  @fallback_to_any true
  @spec from(any) :: {:ok, any} | {:error, :invalid_object}
  def from(object)
end

defimpl ObjectData, for: Object do
  def from(object), do: Object.get_data(object)
end

defimpl ObjectData, for: StreamObject do
  def from(object), do: StreamObject.get_data(object)
end

defimpl ObjectData, for: Any do
  def from(_), do: {:error, :invalid_object}
end
