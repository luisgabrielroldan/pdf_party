defmodule PDFParty.Reader.Numbers do
  @moduledoc """
  Contains functions to parse numbers in a PDF file

  Valid numbers example:
    * 1234
    * -1234
    * 0001234
    * 0.12345
    * .12345
    * -0.12345
    * -.12345

  """

  def is_number?(str),
    do: is_real?(str) or is_int?(str)

  def parse(str) do
      cond do
        is_real?(str) ->
          parse_real(str)

        is_int?(str) ->
          parse_int(str)

        true ->
          throw {:invalid_number, str}
      end
  end

  def is_real?(str),
    do: Regex.match?(~r/^-*\d*\.\d*$/, str)

  def is_int?(str),
    do: Regex.match?(~r/-*\d+$/, str)

  def parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {value, ""} ->
        value

      _ ->
        throw {:invalid_number, str}
    end
  end

  def parse_real("." <> str) do
    parse_real("0." <> str)
  end

  def parse_real("-." <> str) do
    parse_real("-0." <> str)
  end

  def parse_real(str) when is_binary(str) do
    case Float.parse(str) do
      {value, ""} ->
        value

      _ ->
        throw {:invalid_number, str}
    end
  end
end
