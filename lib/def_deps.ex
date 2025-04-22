defmodule DefDeps do
  alias DefDeps.Storage

  @type behaviour_module :: module()
  @type callbacks_module :: module()

  defmacro __using__(opts) do
    Storage.add_behaviour(__CALLER__.module)

    quote do
      Module.put_attribute(__MODULE__, :__def_deps_options__, unquote(opts))

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    implementation =
      env.module
      |> Module.delete_attribute(:__def_deps_options__)
      |> Keyword.get(:default, Module.concat(env.module, Default))
      |> get_working_implementation(env.module)
      |> Macro.escape()

    callbacks = Module.get_attribute(env.module, :callback)

    for {:callback, {:"::", _, [{fun_name, _, args_ast}, _]} = type_spec, _} <- callbacks do
      arity = length(args_ast)
      args = Macro.generate_arguments(arity, env.module) |> Macro.escape()
      spec = type_spec |> Macro.escape()

      # quote теперь используется только непосредственно для inject'a кода
      # Только 2 вещи происходят в контексте модуля behaviour:
      # добавление спеки и определение функции. Всё остальное происходит в контексте DefCallbacks
      quote bind_quoted: [implementation: implementation, fun_name: fun_name, args: args, spec: spec] do
        Elixir.Kernel.@(spec(unquote(spec)))

        def unquote(fun_name)(unquote_splicing(args)) do
          unquote(implementation).unquote(fun_name)(unquote_splicing(args))
        end
      end
    end
  end

  @spec defmocks(library: library :: Mox | Hammox) :: :ok
  def defmocks(library: mock_module) do
    Storage.get_behaviours()
    |> Enum.each(fn behaviour ->
      mock = String.to_atom("#{behaviour}#{mocks_postfix()}")
      mock_module.defmock(mock, for: behaviour)

      Storage.put_callbacks_module(behaviour, mock)
    end)
  end

  @spec service(behaviour_module(), callbacks_module()) :: callbacks_module()
  def service(key, default) do
    Storage.get_callbacks_module(key) || default
  end

  defp mocks_postfix do
    Application.get_env(:def_deps, :mocks_postfix, "Mock")
  end

  defp get_working_implementation(default_impl, callbacks_module) do
    if only_default_implementation?() do
      default_impl
    else
      # Здесь так же не обойтись без контекста caller'a, так как
      # проверять какой сервис дернуть необходимо в момент вызова имплементируемой функции
      quote do
        unquote(__MODULE__).service(unquote_splicing([callbacks_module, default_impl]))
      end
    end
  end

  defp only_default_implementation?() do
    !!Application.get_env(:def_deps, :only_default_impl)
  end
end
