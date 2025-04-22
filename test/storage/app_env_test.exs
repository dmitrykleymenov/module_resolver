defmodule DefDeps.Storage.AppEnvTest do
  use ExUnit.Case
  alias DefDeps.Storage.AppEnv

  setup do
    on_exit(fn ->
      Application.delete_env(:def_deps, :__deps__)
    end)
  end

  describe "get_callbacks_module/1" do
    test "returns nil if there is no implementations stored" do
      refute AppEnv.get_callbacks_module(__MODULE__)
    end

    test "returns implementation from storage" do
      :ok = AppEnv.put_callbacks_module(__MODULE__, TestModule)
      assert AppEnv.get_callbacks_module(__MODULE__) == TestModule
    end
  end

  describe "put_callbacks_module/1" do
    test "inserts callbacks module to storage and keeps previously added ones" do
      assert :ok = AppEnv.put_callbacks_module(BehaviourModule1, CallbacksModule1)
      assert :ok = AppEnv.put_callbacks_module(BehaviourModule2, CallbacksModule2)
      assert :ok = AppEnv.put_callbacks_module(BehaviourModule3, CallbacksModule3)
      assert :ok = AppEnv.put_callbacks_module(BehaviourModule4, CallbacksModule4)

      assert AppEnv.get_callbacks_module(BehaviourModule1) == CallbacksModule1
      assert AppEnv.get_callbacks_module(BehaviourModule2) == CallbacksModule2
      assert AppEnv.get_callbacks_module(BehaviourModule3) == CallbacksModule3
      assert AppEnv.get_callbacks_module(BehaviourModule4) == CallbacksModule4
    end
  end

  describe "get_behaviours/0" do
    test "returns all behaviours which used DefDeps" do
      assert AppEnv.get_behaviours() == [
               DefDepsTest.TestOnlyDefaultBehaviour,
               DefDepsTest.TestNoOptsBehaviour,
               DefDepsTest.TestBehaviour
             ]
    end
  end

  describe "add_behaviour/1" do
    test "adds behaviour" do
      behaviours = Application.get_env(:def_deps, :__behaviours__)
      assert AppEnv.add_behaviour(BehaviourModule) == :ok
      assert AppEnv.get_behaviours() == [BehaviourModule] ++ behaviours
      Application.put_env(:def_deps, :__behaviours__, behaviours)
    end
  end
end
