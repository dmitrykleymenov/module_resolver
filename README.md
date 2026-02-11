# ModuleResolver

Библиотека для разделения(decoupling) зависимостей на уровне модулей с целью упрощения тестирования. Так же предоставляет удобный интерфейс для создания моков этих зависимостей.

## Добвление `module_resolver`'a

Добавляем библиотеку в `mix.exs` файл:

```elixir
def deps do
  [
    ...,
    {:module_resolver, "~> 0.1.0"}
  ]
end
```

## Использование в модулях

Для того чтобы иметь возможность в тестах подменять модуль моками необходимо в модуле с колбеками использовать `use ModuleResolver`, например:

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

Параметр `default_impl` передает имя модуля, который будет использоваться по умолчанию. Например, результатом вызова `MyModule.some_function(5)` будет результат вызова `MyModuleDefaultImplementation.some_function(5)`.

Параметр `default_impl` можно опустить:

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

В таком случае модуль по умолчанию будет формироваться из неймспейса модуля(в нашем случае `MyModule`) и `DefaultImpl`. Т.е в примере выше это будет `MyModule.DefaultImpl`. Это удобно для быстрого разделения зависимостей в существующих модулях.
Например, имеем изначально стандартный модуль:

```elixir
defmodule MyModule
  @spec some_function(integer()) :: {:ok, integer()}
  def some_function(counter), do: {:ok, counter}
end
```
Для того чтобы использовать его Mock в тестах нам необходимо сделать всего 4 небольших шага:
1. Добавить `use ModuleResolver`
2. Существующие спеки перенести в callback'и
3. Все определения функций завернуть в дополнительный модуль `DefaultImpl`
4. В `DefaultImpl` прописать `@behaviour MyModule` в начало и `@impl true` у каждой функции

В итоге получаем:

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

## Использование в тестах

После того как модули были настроены, можно использовать их моки в тестах. Для этого необходимо в `test_helper.exs` указать список модулей первым параметром и двумя опциями: 
- `mock_factory` с помощью которой будут созданы моки 
- `postfix`, который будет добавлен к названию модуля behaviour чтобы получить имя mock модуля

```elixir
  ModuleResolver.Mocks.defmocks([MyModule, MyAnotherModule], mock_factory: Mox, postfix: "Mock")
```
В результате этой команды будут созданы моки `MyModuleMock` и `MyAnotherModuleMock`, которые будут автоматически вызываться при каждом вызове любой функции из модулей `MyModule` и  `MyAnotherModule` соответственно.

С помощь обязательной опции `mock_factory` необходимо передать модуль генерации моков. Модуль генерации должен имплементировать поведение `ModuleResolver.Mocks.MockFactory`. Можно так же использовать `Mox` или `Hammox`.

Опцию `postfix` можно опустить, тогда она по умолчанию будет равна `Mock`

## Конфигурация

По умолчанию модуль имплементации будет выбираться в момент компиляции, при этом на этом этапе функции имплементации будут "вмонтированы" в функцию поведения. В итоге получится нечто вроде:

```elixir
defmodule MyModule
  use ModuleResolver, default_impl: MyModuleDefaultImplementation
  @callback some_function(integer()) :: {:ok, integer()}

  def some_function(count), do: MyModuleDefaultImplementation.some_function(count)
end
```

Относительно решенения без `module_resolver`a overhead составляет лишь 1 дополнительный вызов функции в стек вызовов.

Использование модулей в тестах требует runtime определения модуля имплементации, для этого необходимо сконфигурировать `module_resolver`, передав параметр `compile_default_impl: false`. Например, в конфиг `test.exs` добавить:

```elixir
config :module_resolver, compile_default_impl: false
```

В таком случае поведение будет выбираться каждый раз в момент вызова функции из модуля behaviour

## Benchmarking

Сравнение времени выполнения на примере следующих модулей:

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

Код benchee:

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

Результаты при настройке конфигурации `config :module_resolver, compile_default_impl: false`:

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

Результаты при настройке конфигурации `config :module_resolver, compile_default_impl: true`:

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

**All measurements for memory usage were the same**
```