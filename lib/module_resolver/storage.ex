defmodule ModuleResolver.Storage do
  alias ModuleResolver.Storage.AppEnv

  @moduledoc """
    Behaviour module for storing implementations at runtime
  """
  @type t :: module()

  @callback get_implementation_module(ModuleResolver.behaviour_module()) :: ModuleResolver.implementation_module() | nil
  @callback put_implementation_module(ModuleResolver.behaviour_module(), ModuleResolver.implementation_module()) :: :ok

  @spec get_implementation_module(ModuleResolver.behaviour_module()) :: ModuleResolver.implementation_module() | nil
  def get_implementation_module(behaviour_module) do
    storage().get_implementation_module(behaviour_module)
  end

  @spec put_implementation_module(ModuleResolver.behaviour_module(), ModuleResolver.implementation_module()) :: :ok
  def put_implementation_module(behaviour_module, implementation_module) do
    storage().put_implementation_module(behaviour_module, implementation_module)
  end

  @spec storage() :: t()
  def storage do
    Application.get_env(:module_resolver, :storage, AppEnv)
  end
end
