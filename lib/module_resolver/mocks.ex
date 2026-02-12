defmodule ModuleResolver.Mocks do
  @moduledoc """
    The module stores all the functionality associated with mocks.
  """
  alias ModuleResolver.Storage

  defmodule MockFactory do
    @moduledoc """
      The behaviour for mock generator. It should have `defmock/1` function to define mocks
    """

    @type t :: module()
    @type mock :: module()

    @callback defmock(mock(), for: ModuleResolver.behaviour_module()) :: mock()
  end

  @spec defmocks([ModuleResolver.behaviour_module()], mock_factory: MockFactory.t(), postfix: String.t()) :: :ok
  def defmocks(behaviours, opts) do
    mock_factory = Keyword.fetch!(opts, :mock_factory)
    postfix = Keyword.get(opts, :postfix, "Mock")

    Enum.each(behaviours, fn behaviour ->
      implementation_mock = String.to_atom("#{behaviour}#{postfix}")
      mock_factory.defmock(implementation_mock, for: behaviour)

      Storage.put_implementation_module(behaviour, implementation_mock)
    end)
  end
end
