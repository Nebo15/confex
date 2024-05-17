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
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      docs: [source_url: @source_url, source_ref: "v#\{@version\}", main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [applications: []]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:excoveralls, ">= 0.7.0", only: [:dev, :test]},
      {:credo, ">= 0.8.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:inch_ex, ">= 0.0.0", only: :docs}
    ]
  end

  defp description do
    """
    Helper module that provides a nice way to read configuration at runtime from environment variables or
    via adapter-supported interface.
    """
  end

  defp package do
    [
      contributors: ["Andrew Dryga"],
      maintainers: ["Nebo #15"],
      licenses: ["LICENSE.md"],
      links: %{Changelog: "#{@source_url}/blob/master/CHANGELOG.md}", GitHub: @source_url},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end
end
