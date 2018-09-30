defmodule Exred.Node.Picar.MixProject do
  use Mix.Project

  @description "Exred node to control a SunFounder PiCar"

  def project do
    [
      app: :exred_node_picar,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package()
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
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
      {:exred_library, "~> 0.1.11"},
      {:elixir_ale, "~> 1.0"},
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Zsolt Keszthelyi"],
      links: %{
        "GitHub" => "https://github.com/exredorg/exred_node_picar",
        "Exred" => "http://exred.org"
      },
      files: ["lib", "mix.exs", "README.md", "LICENSE"]
    }
  end

end
