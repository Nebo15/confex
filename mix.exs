defmodule Confex.Mixfile do
  use Mix.Project

  @version "3.2.1"

  def project do
    [app: :confex,
     description: description(),
     package: package(),
     version: @version,
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test],
     docs: [source_ref: "v#\{@version\}", main: "readme", extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: []]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, ">= 0.16.0",     only: [:dev, :test]},
     {:excoveralls, ">= 0.7.0", only: [:dev, :test]},
     {:dogma, "> 0.1.0",        only: [:dev, :test]},
     {:credo, ">= 0.8.0",       only: [:dev, :test]}]
  end

  defp description do
    """
    Helper module that provides a nice way to read configuration at runtime from environment variables or
    via adapter-supported interface.
    """
  end

  # Settings for publishing in Hex package manager:
  defp package do
    [contributors: ["Nebo #15"],
     maintainers: ["Nebo #15"],
     licenses: ["LISENSE.md"],
     links: %{github: "https://github.com/Nebo15/confex"},
     files: ~w(lib LICENSE.md mix.exs README.md)]
  end
end
