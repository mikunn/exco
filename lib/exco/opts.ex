defmodule Exco.Opts do
  @moduledoc false

  def set_defaults(opts \\ [], default_opts \\ []) do
    Enum.map(default_opts, &apply_default(opts, &1))
  end
  
  def normalize(opts, op, enum, normalized \\ [])
  def normalize([{:max_concurrency, value} | rest], op, enum, normalized) do
    normalized = case value >= length(enum) do
      true ->
        [max_concurrency: :full] ++ normalized
      false ->
        [max_concurrency: value] ++ normalized
    end

    normalize(rest, op, enum, normalized)
  end

  def normalize(_opts, _op, _enum, normalized) do
    normalized
  end

  defp apply_default(opts, {key, _val} = default) do
    set_value = opts[key]

    case is_nil(set_value) do
      true -> default
      false -> {key, set_value} 
    end
  end
end
