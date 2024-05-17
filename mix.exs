defmodule Confex.Mixfile do
  use Mix.Project

  @source_url "https://github.com/Nebo15/confex"
  @version "3.5.1"

  def project do
    [
      app: :confex,
      description: description(),
      package: package(),
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:excoveralls, ">= 0.7.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.4", only: [:dev]}
    ]
  end

  defp package do
    [
      description: description(),
      contributors: ["Andrew Dryga"],
      maintainers: ["Andrew Dryga"],
      licenses: ["MIT"],
      files: ~w(lib LICENSE.md mix.exs README.md),
      links: %{
        Changelog: "#{@source_url}/blob/master/CHANGELOG.md}",
        GitHub: @source_url
      }
    ]
  end

  defp description do
    """
    Helper module that provides a nice way to read configuration at runtime from environment variables or
    via adapter-supported interface.
    """
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      formatters: ["html"]
    ]
  end
end
