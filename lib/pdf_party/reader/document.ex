defmodule PDFParty.Reader.Document do
  alias PDFParty.Reader.{
    Object,
    ObjectData,
    Parser,
    StreamObject,
    Version,
    XRef,
  }

  @type t :: %__MODULE__{
          version: String.t(),
          xref: %XRef{},
          objects: list(),
          path: String.t()
        }

  @type object :: %Object{} | %StreamObject{}

  defstruct version: nil, xref: nil, objects: nil, path: nil

  @file_opts [:read, :raw, :read_ahead]

  @spec read(String.t(), list()) :: {:ok, t()} | {:error, term()}
  def read(path, _opts \\ []) do
    path = Path.absname(path)

    with {:ok, %{size: file_size}} <- File.stat(path),
         {:ok, io_device} <- File.open(path, @file_opts),
         {:ok, version} <- Version.read(io_device),
         {:ok, xref} <- XRef.load(io_device, file_size),
         {:ok, objects} <- preload_objects(io_device, xref) do
      document = %__MODULE__{
        version: version,
        xref: xref,
        objects: objects,
        path: path
      }

      {:ok, document}
    end
  end

  @spec get_object(Object.ref(), t()) :: {:ok, object()} | :error
  def get_object({:ref, id, gen}, %__MODULE__{objects: objects}) do
    objects
    |> Enum.find(&match?(%{id: ^id, gen: ^gen}, &1))
    |> case do
      nil -> :error
      obj -> {:ok, obj}
    end
  end

  def get_object_data({:ref, _, _} = ref, %__MODULE__{} = document) do
    with {:ok, page} <- get_object(ref, document),
         {:ok, data} <- ObjectData.from(page) do
      {:ok, data}
    end
  end

  defp preload_objects(io_device, %{entries: entries}),
    do: load_objects(entries, io_device, [])

  defp load_objects([], _io_device, acc),
    do: {:ok, acc}

  defp load_objects([{_id, _gen, offset, :n} | rest], io_device, acc) do
    case Parser.parse(io_device, offset) do
      {:ok, [%Object{} =  obj]} ->
        load_objects(rest, io_device, acc ++ [obj])

      {:ok, [%StreamObject{} =  obj]} ->
        load_objects(rest, io_device, acc ++ [obj])

      {:ok, _} ->
        {:error, :invalid_object}

      {:error, error} ->
        {:error, {:load_object, offset, error}}
    end
  end

  defp load_objects([_ | rest], io_device, acc),
    do: load_objects(rest, io_device, acc)
end
