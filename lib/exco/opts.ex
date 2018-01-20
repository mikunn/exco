defmodule Exco.Opts do
  @moduledoc false

  def set_defaults(opts \\ [], default_opts \\ []) do
    Enum.map(default_opts, &apply_default(opts, &1))
  end
  
  defp apply_default(opts, {key, _val} = default) do
    set_value = opts[key]

    case is_nil(set_value) do
      true -> default
      false -> {key, set_value} 
    end
  end
end
