defmodule Releaser.UI do
  @moduledoc """
  ANSI terminal output helpers for releaser mix tasks.
  """

  def info(msg), do: Mix.shell().info(msg)
  def error(msg), do: Mix.shell().error(msg)

  def bright(text), do: "#{IO.ANSI.bright()}#{text}#{IO.ANSI.reset()}"
  def green(text), do: "#{IO.ANSI.green()}#{text}#{IO.ANSI.reset()}"
  def yellow(text), do: "#{IO.ANSI.yellow()}#{text}#{IO.ANSI.reset()}"
  def cyan(text), do: "#{IO.ANSI.cyan()}#{text}#{IO.ANSI.reset()}"
  def red(text), do: "#{IO.ANSI.red()}#{text}#{IO.ANSI.reset()}"
  def dim(text), do: "#{IO.ANSI.faint()}#{text}#{IO.ANSI.reset()}"

  def arrow(old, new), do: "#{yellow(old)} → #{green(new)}"

  def table_row(cols, widths) do
    cols
    |> Enum.zip(widths)
    |> Enum.map(fn {col, width} -> String.pad_trailing(col, width) end)
    |> Enum.join("  ")
  end
end
