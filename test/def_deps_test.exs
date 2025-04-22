defmodule DefDepsTest do
  use ExUnit.Case
  alias DefDeps.Storage

  # Hammox для получения информации о типах callback-ов использует Code.Typespec.fetch_callbacks,
  # который возвращает ошибку если модуль был скомпилирован но файл .beam для него ещё не создан как в этом тесте.
  import Mox
  setup :verify_on_exit!

  defmodule TestBehaviour do
    use DefDeps, default: MockDefaultImpl

    @callback init() :: {:ok, integer}
    @callback succ(integer) :: :ok
  end

  defmodule TestNoOptsBehaviour do
    use DefDeps

    @callback init() :: {:ok, integer}
  end

  Mox.defmock(DefDepsTest.TestNoOptsBehaviour.Default, for: TestNoOptsBehaviour)

  Application.put_env(:def_deps, :only_default_impl, true)

  defmodule TestOnlyDefaultBehaviour do
    use DefDeps, default: MockDefaultImpl

    @callback init() :: {:ok, integer}
    @callback succ(integer) :: :ok
  end

  Application.put_env(:def_deps, :only_default_impl, false)

  Mox.defmock(MockStorage, for: Storage)
  Application.put_env(:def_deps, :storage, MockStorage)

  Mox.defmock(MockDefaultImpl, for: TestBehaviour)
  Mox.defmock(MockStoredImpl, for: TestBehaviour)

  describe "use" do
    test "defines all behaviour callbacks" do
      assert {:init, 0} in TestBehaviour.__info__(:functions)
      assert {:succ, 1} in TestBehaviour.__info__(:functions)
    end

    test "setups requests forwarding to default implementation when there are no stored calbacks modules" do
      num = :rand.uniform(9999)

      MockStorage
      |> expect(:get_callbacks_module, fn module ->
        assert module == TestBehaviour
        nil
      end)

      MockDefaultImpl
      |> expect(:init, fn -> num end)

      assert TestBehaviour.init() == num
    end

    test "uses Default module when the `default` option isn't set" do
      num = :rand.uniform(9999)

      MockStorage
      |> expect(:get_callbacks_module, fn module ->
        assert module == TestNoOptsBehaviour
        nil
      end)

      DefDepsTest.TestNoOptsBehaviour.Default
      |> expect(:init, fn -> num end)

      assert TestNoOptsBehaviour.init() == num
    end

    test "setups requests forwarding to stored implementation" do
      num = :rand.uniform(9999)

      MockStorage
      |> expect(:get_callbacks_module, fn module ->
        assert module == TestBehaviour
        MockStoredImpl
      end)

      MockStoredImpl
      |> expect(:init, fn -> num end)

      assert TestBehaviour.init() == num
    end

    test "setups requests forwarding directly to implementation, without using of the storage" do
      num = :rand.uniform(9999)

      MockDefaultImpl
      |> expect(:init, fn -> num end)

      assert TestOnlyDefaultBehaviour.init() == num
    end
  end

  describe "service/2" do
    test "returns found implementation" do
      MockStorage
      |> expect(:get_callbacks_module, fn module ->
        assert module == TestBehaviour
        TestBehaviourMock
      end)

      assert DefDeps.service(TestBehaviour, MockDefaultImpl) == TestBehaviourMock
    end

    test "returns default implementation when there is no such implementation in storage" do
      MockStorage
      |> expect(:get_callbacks_module, fn module ->
        assert module == TestBehaviour
        nil
      end)

      assert DefDeps.service(TestBehaviour, MockDefaultImpl) == MockDefaultImpl
    end
  end

  describe "defmocks/2" do
    test "defines mocks for behaviours" do
      expected_implementations = %{
        TestBehaviour => DefDepsTest.TestBehaviourMock,
        TestOnlyDefaultBehaviour => DefDepsTest.TestOnlyDefaultBehaviourMock
      }

      MockStorage
      |> expect(:get_behaviours, fn ->
        [TestBehaviour, TestOnlyDefaultBehaviour]
      end)
      |> expect(:put_callbacks_module, 2, fn behaviour, mock ->
        assert behaviour in Map.keys(expected_implementations)
        assert expected_implementations[behaviour] == mock
      end)

      DefDeps.defmocks(library: Mox)
    end
  end
end
