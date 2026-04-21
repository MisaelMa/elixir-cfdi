defmodule SaxonHe do
  @moduledoc """
  Wrapper around the Saxon-HE Java archive for XSLT 3.0 and XQuery 3.1.

  Configure the JAR path with `config :saxon_he, :jar_path, "/path/to/saxon-he-12.jar"`
  or the `SAXON_JAR` environment variable.
  """

  @doc """
  Returns the configured path to `saxon-he-*.jar`.
  """
  @spec saxon_jar_path() :: String.t()
  def saxon_jar_path do
    System.get_env("SAXON_JAR") ||
      Application.get_env(:saxon_he, :jar_path) ||
      raise ArgumentError,
            "Set SAXON_JAR or config :saxon_he, :jar_path to your Saxon-HE JAR path"
  end
end
