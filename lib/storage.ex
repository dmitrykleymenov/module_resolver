defmodule DefDeps.Storage do
  alias DefDeps.Storage.AppEnv

  @callback get_callbacks_module(DefDeps.behaviour_module()) :: DefDeps.callbacks_module() | nil
  @callback put_callbacks_module(DefDeps.behaviour_module(), DefDeps.callbacks_module()) :: :ok
  @callback add_behaviour(DefDeps.behaviour_module()) :: :ok
  @callback get_behaviours() :: [DefDeps.behaviour_module()]

  @spec add_behaviour(DefDeps.behaviour_module()) :: :ok
  def add_behaviour(behaviour_module) do
    storage().add_behaviour(behaviour_module)
  end

  @spec get_behaviours() :: [DefDeps.behaviour_module()]
  def get_behaviours() do
    storage().get_behaviours()
  end

  @spec get_callbacks_module(DefDeps.behaviour_module()) :: DefDeps.callbacks_module() | nil
  def get_callbacks_module(behaviour_module) do
    storage().get_callbacks_module(behaviour_module)
  end

  @spec put_callbacks_module(DefDeps.behaviour_module(), DefDeps.callbacks_module()) :: :ok
  def put_callbacks_module(behaviour_module, callbacks_module) do
    storage().put_callbacks_module(behaviour_module, callbacks_module)
  end

  def storage do
    Application.get_env(:def_deps, :storage, AppEnv)
  end
end
