defmodule PDFParty.Reader.Str do
  @moduledoc """
  Reader string utils

  TODO: Implement strings decoding
  """

  defstruct value: nil, is_hex?: false

  def new(is_hex? \\ false) do
    %__MODULE__{is_hex?: is_hex?}
  end

  def assign(%__MODULE__{} = str, value),
    do: %{str | value: value}

  def build(%__MODULE__{is_hex?: true, value: value}) do
    String.length(value)
    |> rem(2)
    |> case do
      0 ->
        Base.decode16!(value)

      1 ->
        Base.decode16!(value <> "0")
    end
  end

  def build(%__MODULE__{value: value}),
    do: value
end
