defmodule ModuleResolver.Storage.AppEnvTest do
  use ExUnit.Case
  alias ModuleResolver.Storage.AppEnv

  setup do
    on_exit(fn ->
      Application.delete_env(:module_resolver, :__resolvings__)
    end)
  end

  describe "get_implementation_module/1" do
    test "returns an implementation from storage" do
      :ok = AppEnv.put_implementation_module(__MODULE__, TestModule)
      assert AppEnv.get_implementation_module(__MODULE__) == TestModule
    end

    test "returns nil if there are no implementations stored" do
      refute AppEnv.get_implementation_module(__MODULE__)
    end
  end

  describe "put_implementation_module/2" do
    test "inserts implementation module to the storage and keeps previously added ones" do
      assert AppEnv.put_implementation_module(BehaviourModule1, CallbacksModule1) == :ok
      assert AppEnv.put_implementation_module(BehaviourModule2, CallbacksModule2) == :ok
      assert AppEnv.put_implementation_module(BehaviourModule3, CallbacksModule3) == :ok
      assert AppEnv.put_implementation_module(BehaviourModule4, CallbacksModule4) == :ok

      assert AppEnv.get_implementation_module(BehaviourModule1) == CallbacksModule1
      assert AppEnv.get_implementation_module(BehaviourModule2) == CallbacksModule2
      assert AppEnv.get_implementation_module(BehaviourModule3) == CallbacksModule3
      assert AppEnv.get_implementation_module(BehaviourModule4) == CallbacksModule4
    end

    test "rewrites implementation module in the storage" do
      AppEnv.put_implementation_module(BehaviourModule1, CallbacksModule1)
      assert AppEnv.put_implementation_module(BehaviourModule1, CallbacksModule2) == :ok

      assert AppEnv.get_implementation_module(BehaviourModule1) == CallbacksModule2
    end
  end
end
