# ModuleResolver

A library for decoupling module-level dependencies to simplify testing. It also provides a convenient interface for creating mocks of these dependencies.

## Installation

Add `:module_resolver` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:module_resolver, "~> 0.1.0"}
  ]
end
```

## Usage

You may use `ModuleResolver` in a module that is expected to be mocked. For example:

```elixir
defmodule MyModule
  use ModuleResolver, default_impl: MyModuleDefaultImplementation

  @callback some_function(integer()) :: {:ok, integer()}
end

defmodule MyModuleDefaultImplementation
  @behaviour MyModule
  
  @impl true
  def some_function(counter), do: {:ok, counter}
end
```
Here `MyModule` uses `ModuleResolver` and specifies the default implementation module through `default_impl` option. After defining a callback in the behaviour module and the function itself in the implementation module, the call to `MyModule.some_function/1` will be delegated to the `MyModuleDefaultImplementation.some_function/1`.

To define mocks in tests you may do this in the `test_helper.exs` file:

```elixir
  ModuleResolver.Mocks.defmocks([MyModule], mock_factory: Mox, postfix: "Mock")
```

The first agrument here is a list of behaviour modules and the second one is `options`. There are two possible options:

- `mock_factory`, implementation of `BeamMetrics.Mocks.MockFactory` behaviour. It can be `Mox` or `Hammox` as well. 
- `postfix`, will be added to the end of the behaviour module name to create a mock module name. Can be omitted. By default: `"Mock'`

To use these mocks, you need to disable implementation mounting at compile time. Add the following to the `test.exs` file:

```elixir
config :module_resolver, compile_default_impl: false
```

Now call to `MyModule.some_function/1` in test environment wil be delegated to `MyModuleMock.some_function/1`. In other environments the module under `default_impl` will be compiled into behaviour.

## Compile-time/runtime

By default, implementation is compiled into the behaviour module, and after compilation, the result roughly looks like:

```Elixir
defmodule MyModule
  def some_function(count), do: MyModuleDefaultImplementation.some_function(count)
end
```

When `compile_default_impl: false` is set, the implementation is determined at runtime. If there is no mock for a given behavior, a default implementation will be used, so integration tests can use the actual implementation without defining mocks.

## Other use cases

The `default_impl` option may be omitted:

```elixir
defmodule MyModule
  use ModuleResolver

  @callback some_function(integer()) :: {:ok, integer()}

  defmodule DefaultImpl
    @behaviour MyModule
  
    @impl true
    def some_function(counter), do: {:ok, counter}
  end
end
```

In this case default implementation will be set as `__MODULE__.DefaultImpl`. In the code above it will be `MyModule.DefaultImpl`. It's helpful when you need to decouple existed modules. For example, we have a module such as:

```elixir
defmodule MyExistedModule
  @spec existed_function(integer()) :: {:ok, integer()}
  def existed_function(counter), do: {:ok, counter}
end
```

To use `MyExistedModuleMock` instead of `MyExistedModule` in tests, you need to follow 5 steps:

1. Add `use ModuleResolver`
2. Replace `@spec` with `@callback`.
3. Wrap all function definitions in the `DefaultImpl` module
4. Add `@behaviour MyExistedModule` to the top of the `DefaultImpl` module and `@impl true` to each function.
5. Add `MyExistedModule` to the mocks list in `ModuleResolver.Mocks.defmocks/2`

As result:

```elixir
defmodule MyExistedModule
  use ModuleResolver

  @callback existed_function(integer()) :: {:ok, integer()}

  defmodule DefaultImpl
    @behaviour MyExistedModule
  
    @impl true
    def existed_function(counter), do: {:ok, counter}
  end
end
```

## Benchmarking

```elixir
defmodule BenchTestsBehaviour do
  use ModuleResolver, default_impl: BenchTestsImplementation

  @callback some_fun(integer()) :: {:ok, integer()}
end

defmodule BenchTestsImplementation do
  @behaviour BenchTestsBehaviour

  @impl true
  def some_fun(number), do: {:ok, number}
end
```

benchee code:

```elixir
Benchee.run(
  %{
    "implementation direct call" => fn ->
      Enum.each(
        0..100_000,
        fn num -> BenchTestsImplementation.some_fun(num) end
      )
    end,
    "behaviour call" => fn ->
      Enum.each(
        0..100_000,
        fn num -> BenchTestsBehaviour.some_fun(num) end
      )
    end
  },
  time: 10,
  memory_time: 2
)
```

Results with `config :module_resolver, compile_default_impl: false`:

```bash
Name                                 ips        average  deviation         median         99th %
implementation direct call         20.88       47.89 ms    ±12.12%       46.78 ms       72.11 ms
behaviour call                     10.55       94.81 ms    ±11.37%       91.97 ms      131.05 ms

Comparison: 
implementation direct call         20.88
behaviour call                     10.55 - 1.98x slower +46.92 ms

Memory usage statistics:

Name                          Memory usage
implementation direct call        59.52 MB
behaviour call                    65.63 MB - 1.10x memory usage +6.10 MB
```

Results with `config :module_resolver, compile_default_impl: true`:

```bash
Name                                 ips        average  deviation         median         99th %
implementation direct call         22.32       44.79 ms     ±7.09%       44.26 ms       56.62 ms
behaviour call                     21.81       45.86 ms     ±8.48%       45.40 ms       55.53 ms

Comparison: 
implementation direct call         22.32
behaviour call                     21.81 - 1.02x slower +1.07 ms

Memory usage statistics:

Name                          Memory usage
implementation direct call        59.52 MB
behaviour call                    59.52 MB - 1.00x memory usage -0.00018 MB
```