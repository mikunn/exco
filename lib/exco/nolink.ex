defmodule Exco.Nolink do
  def map(enumerable, fun, opts \\ []) do
    opts = Keyword.put(opts, :linkage, :nolink)
    Exco.map(enumerable, fun, opts)
  end

  def each(enumerable, fun, opts \\ []) do
    opts = Keyword.put(opts, :linkage, :nolink)
    Exco.each(enumerable, fun, opts)
  end

  def filter(enumerable, fun, opts \\ []) do
    opts = Keyword.put(opts, :linkage, :nolink)
    Exco.filter(enumerable, fun, opts)
  end
end
