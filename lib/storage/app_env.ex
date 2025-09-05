defmodule DefDeps.Storage.AppEnv do
  @behaviour DefDeps.Storage

  @impl true
  def get_callbacks_module(behaviour_module) do
    Application.get_env(:def_deps, :__deps__, %{})
    |> Access.get(behaviour_module)
  end

  @impl true
  def put_callbacks_module(behaviour_module, callbacks_module) do
    deps = Application.get_env(:def_deps, :__deps__, %{})
    Application.put_env(:def_deps, :__deps__, Map.put(deps, behaviour_module, callbacks_module))
  end
end
