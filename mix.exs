defmodule ModuleResolver.MixProject do
  use Mix.Project

  @test_envs [:test]
  @dev_envs [:dev]
  @url "https://github.com/dmitrykleymenov/module_resolver"

  def project do
    [
      app: :module_resolver,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      dialyzer: dialyzer(),
      source_url: @url,
      aliases: aliases(),
      preferred_cli_env: [
        cover: :test,
        "cover.detail": :test,
        "cover.html": :test,
        "cover.filter": :test,
        "cover.lint": :test,
        credo: :test,
        dialyzer: :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mox, "~> 1.0", only: @test_envs},
      {:credo, "~> 1.7", only: @test_envs ++ @dev_envs, runtime: false},
      {:dialyxir, "~> 1.4", only: @test_envs ++ @dev_envs, runtime: false},
      {:excoveralls, "~> 0.18.1", only: @test_envs},
      {:excoveralls_linter, "~> 0.2.1", only: @test_envs}
    ]
  end

  defp description do
    "Library for modules decoupling"
  end

  defp dialyzer do
    [
      flags: [
        :error_handling,
        :race_conditions,
        :underspecs,
        :unmatched_returns,
        :unknown
      ],
      plt_add_apps: [:ex_unit, :mix],
      # для удобного кэширования plt в CI
      plt_local_path: "_build/plt/"
    ]
  end

  defp package do
    [
      name: :module_resolver,
      licenses: [],
      links: [],
      maintainers: ["dmitrykleymenov"],
      files: ["lib", "mix.exs", "README*"]
    ]
  end

  defp aliases do
    [
      cover: ["coveralls --sort cov:desc"],
      "cover.lint": [
        "coveralls.lint --required-project-coverage=0.99 --missed-lines-threshold=2 --required-file-coverage=0.9"
      ],
      "cover.html": ["coveralls.html"],
      "cover.detail": ["coveralls.detail --filter"]
    ]
  end
end
