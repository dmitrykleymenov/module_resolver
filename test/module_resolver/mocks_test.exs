defmodule ModuleResolver.MocksTest do
  use ExUnit.Case

  import Mox

  defmodule TestBehaviour1 do
    use ModuleResolver, default_impl: MockDefaultImpl1

    @callback init() :: {:ok, integer()}
    @callback increment(integer()) :: integer()
  end

  defmodule TestBehaviour2 do
    use ModuleResolver, default_impl: MockDefaultImpl2

    @callback init() :: {:ok, integer()}
    @callback increment(integer()) :: integer()
  end

  setup :verify_on_exit!

  describe "defmocks/2" do
    test "defines mocks for behaviours" do
      expected_implementations = %{
        TestBehaviour1 => ModuleResolver.MocksTest.TestBehaviour1Mock,
        TestBehaviour2 => ModuleResolver.MocksTest.TestBehaviour2Mock
      }

      expect_storage_put_implementations(expected_implementations)

      ModuleResolver.Mocks.defmocks([TestBehaviour1, TestBehaviour2], mock_factory: Mox)
    end

    test "defines mocks for behaviours with the given postfix" do
      expected_implementations = %{
        TestBehaviour1 => ModuleResolver.MocksTest.TestBehaviour1NotAMock,
        TestBehaviour2 => ModuleResolver.MocksTest.TestBehaviour2NotAMock
      }

      expect_storage_put_implementations(expected_implementations)

      ModuleResolver.Mocks.defmocks([TestBehaviour1, TestBehaviour2], mock_factory: Mox, postfix: "NotAMock")
    end
  end

  defp expect_storage_put_implementations(expected_implementations) do
    count = Enum.count(expected_implementations)

    StorageMock
    |> expect(:put_implementation_module, count, fn behaviour, mock ->
      assert behaviour in Map.keys(expected_implementations)
      assert mock == expected_implementations[behaviour]
    end)
  end
end
