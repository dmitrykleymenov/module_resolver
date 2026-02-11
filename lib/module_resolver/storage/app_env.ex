defmodule ModuleResolver.Storage.AppEnv do
  @moduledoc """
    Модуль имплементации ModuleResolver.Storage с использованием Application environment
  """

  @behaviour ModuleResolver.Storage
  @application_name :module_resolver
  @resolvings_app_key :__resolvings__

  @impl true
  def get_implementation_module(behaviour_module) do
    Application.get_env(@application_name, @resolvings_app_key, %{})
    |> Access.get(behaviour_module)
  end

  @impl true
  def put_implementation_module(behaviour_module, implementation_module) do
    impls = Application.get_env(@application_name, @resolvings_app_key, %{})
    Application.put_env(@application_name, @resolvings_app_key, Map.put(impls, behaviour_module, implementation_module))
  end
end
