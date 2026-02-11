defmodule ModuleResolver do
  @moduledoc """
    Библиотека для разделения(decoupling) зависимостей на уровне модулей с целью упрощения тестирования
  """

  defmodule InvalidOptionError do
    defexception [:message]

    @impl true
    def exception(option) do
      msg = "#{inspect(option)} is not a valid option. Valid options are: #{inspect(ModuleResolver.possible_options())}"

      %InvalidOptionError{message: msg}
    end
  end

  alias ModuleResolver.Storage

  @type behaviour_module :: module()
  @type implementation_module :: module()

  @possible_options [:default_impl]

  defmacro __using__(opts) do
    validate_options(opts)

    quote do
      Module.put_attribute(__MODULE__, :__module_resolver_options__, unquote(opts))

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    implementation =
      env.module
      |> Module.delete_attribute(:__module_resolver_options__)
      |> Keyword.get(:default_impl, Module.concat(env.module, DefaultImpl))
      |> get_working_implementation(env.module)
      |> Macro.escape()

    callbacks = Module.get_attribute(env.module, :callback)

    for {:callback, {:"::", _, [{fun_name, _, args_ast}, _]} = type_spec, _} <- callbacks do
      arity = length(args_ast)
      args = Macro.generate_arguments(arity, env.module) |> Macro.escape()
      spec = type_spec |> Macro.escape()

      # quote теперь используется только непосредственно для inject'a кода
      # Только 2 вещи происходят в контексте модуля behaviour:
      # добавление спеки и определение функции. Всё остальное происходит в контексте ModuleResolver
      quote bind_quoted: [implementation: implementation, fun_name: fun_name, args: args, spec: spec] do
        Elixir.Kernel.@(spec(unquote(spec)))

        def unquote(fun_name)(unquote_splicing(args)) do
          unquote(implementation).unquote(fun_name)(unquote_splicing(args))
        end
      end
    end
  end

  @spec implementation(behaviour_module(), fallback_impl :: implementation_module()) ::
          implementation_module()
  def implementation(behaviour, fallback_impl) do
    Storage.get_implementation_module(behaviour) || fallback_impl
  end

  @spec possible_options() :: [:default_impl, ...]
  def possible_options, do: @possible_options

  defp get_working_implementation(default_impl, implementation_module) do
    if compile_only_default?() do
      default_impl
    else
      # Здесь так же не обойтись без контекста caller'a, так как
      # проверять какой сервис дернуть необходимо в момент вызова имплементируемой функции
      quote do
        unquote(__MODULE__).implementation(unquote_splicing([implementation_module, default_impl]))
      end
    end
  end

  defp compile_only_default? do
    Application.get_env(:module_resolver, :compile_default_impl, true)
  end

  defp validate_options(opts) do
    opts
    |> Enum.each(fn {option, _value} ->
      if option not in ModuleResolver.possible_options(), do: raise(ModuleResolver.InvalidOptionError, option)
    end)
  end
end
