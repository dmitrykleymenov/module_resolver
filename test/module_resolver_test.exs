defmodule ModuleResolverTest do
  use ExUnit.Case
  alias ModuleResolver.InvalidOptionError

  import Mox

  # To prevent direct compilation of the default implementation, the `compile_default_impl` option must be set to false.
  Application.put_env(:module_resolver, :compile_default_impl, false)

  defmodule TestBehaviour do
    use ModuleResolver, default_impl: DefaultImplMock

    @callback init() :: {:ok, integer()}
    @callback increment(integer()) :: integer()
  end

  defmodule TestNoOptsBehaviour do
    use ModuleResolver

    @callback init() :: {:ok, integer()}
    @callback increment(integer()) :: integer()
  end

  # We return the option value `true` to check for these cases.
  Application.put_env(:module_resolver, :compile_default_impl, true)

  defmodule TestOnlyDefaultBehaviour do
    use ModuleResolver, default_impl: DefaultImplMock

    @callback init() :: {:ok, integer()}
    @callback increment(integer()) :: integer()
  end

  Mox.defmock(ModuleResolverTest.TestNoOptsBehaviour.DefaultImpl, for: TestNoOptsBehaviour)

  Application.put_env(:module_resolver, :storage, StorageMock)

  Mox.defmock(DefaultImplMock, for: TestBehaviour)
  Mox.defmock(StoredImplMock, for: TestBehaviour)

  setup :verify_on_exit!

  describe "use TestBehaviour" do
    test "defines all behaviour callbacks" do
      assert {:init, 0} in TestBehaviour.__info__(:functions)
      assert {:increment, 1} in TestBehaviour.__info__(:functions)
    end

    test "setups requests forwarding to default implementation when there are no stored calbacks modules" do
      num = :rand.uniform(9999)

      StorageMock
      |> expect(:get_implementation_module, fn module ->
        assert module == TestBehaviour
        nil
      end)

      DefaultImplMock
      |> expect(:init, fn -> {:ok, num} end)

      assert TestBehaviour.init() == {:ok, num}
    end

    test "setups requests forwarding to stored implementation" do
      num = :rand.uniform(9999)

      StorageMock
      |> expect(:get_implementation_module, fn module ->
        assert module == TestBehaviour
        StoredImplMock
      end)

      StoredImplMock
      |> expect(:init, fn -> {:ok, num} end)

      assert TestBehaviour.init() == {:ok, num}
    end
  end

  describe "use TestNoOptsBehaviour" do
    test "defines all behaviour callbacks" do
      assert {:init, 0} in TestNoOptsBehaviour.__info__(:functions)
      assert {:increment, 1} in TestNoOptsBehaviour.__info__(:functions)
    end

    test "uses BehaviourModule.DefaultImpl module" do
      num = :rand.uniform(9999)

      StorageMock
      |> expect(:get_implementation_module, fn module ->
        assert module == TestNoOptsBehaviour
        nil
      end)

      ModuleResolverTest.TestNoOptsBehaviour.DefaultImpl
      |> expect(:init, fn -> {:ok, num} end)

      assert TestNoOptsBehaviour.init() == {:ok, num}
    end

    test "setups requests forwarding to stored implementation" do
      num = :rand.uniform(9999)

      StorageMock
      |> expect(:get_implementation_module, fn module ->
        assert module == TestNoOptsBehaviour
        StoredImplMock
      end)

      StoredImplMock
      |> expect(:init, fn -> {:ok, num} end)

      assert TestNoOptsBehaviour.init() == {:ok, num}
    end
  end

  describe "use TestOnlyDefaultBehaviour" do
    test "defines all behaviour callbacks" do
      assert {:init, 0} in TestOnlyDefaultBehaviour.__info__(:functions)
      assert {:increment, 1} in TestOnlyDefaultBehaviour.__info__(:functions)
    end

    test "setups requests forwarding directly to implementation, without using of the storage" do
      num = :rand.uniform(9999)

      StorageMock
      |> expect(:get_implementation_module, 0, fn _ -> raise "should not be invoked" end)

      DefaultImplMock
      |> expect(:init, fn -> {:ok, num} end)

      assert TestOnlyDefaultBehaviour.init() == {:ok, num}
    end
  end

  describe "implementation/2" do
    test "returns a found implementation" do
      StorageMock
      |> expect(:get_implementation_module, fn module ->
        assert module == TestBehaviour
        TestBehaviourMock
      end)

      assert ModuleResolver.implementation(TestBehaviour, DefaultImplMock) == TestBehaviourMock
    end

    test "returns the default implementation when there are no implementations for the behaviour in the storage" do
      StorageMock
      |> expect(:get_implementation_module, fn module ->
        assert module == TestBehaviour
        nil
      end)

      assert ModuleResolver.implementation(TestBehaviour, DefaultImplMock) == DefaultImplMock
    end
  end

  describe "InvalidOptionError" do
    test "raises and tells about possible options" do
      error =
        assert_raise InvalidOptionError, fn ->
          defmodule InvalidBehaviour do
            use ModuleResolver, invalid_option: :value

            @callback init() :: {:ok, integer()}
            @callback increment(integer()) :: integer()
          end
        end

      assert %InvalidOptionError{message: message} = error
      assert message =~ ~r/:invalid_option is not a valid option./
      assert message =~ ~r/Valid options are: \[.+\]/
    end
  end
end
