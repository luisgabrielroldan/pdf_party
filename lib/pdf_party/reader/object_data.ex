alias PDFParty.Reader.{
  Object,
  ObjectData,
  StreamObject,
}

defprotocol ObjectData do
  @spec from(%Object{} | %StreamObject{}) :: {:error, :invalid_object} | {:ok, map()}

  def from(object)
end

defimpl ObjectData, for: Object do
  def from(object), do: Object.get_data(object)
end

defimpl ObjectData, for: StreamObject do
  def from(object), do: StreamObject.get_data(object)
end

defimpl ObjectData, for: Atom do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: BitString do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: Float do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: Function do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: Integer do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: List do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: Map do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: PID do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: Port do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: Reference do
  def from(_), do: {:error, :invalid_object}
end

defimpl ObjectData, for: Tuple do
  def from(_), do: {:error, :invalid_object}
end
