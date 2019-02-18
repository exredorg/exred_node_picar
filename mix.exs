defmodule Exred.Node.Picar.MixProject do
  use Mix.Project

  @description "Exred node to control a SunFounder PiCar"
  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :exred_node_picar,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: @description,
      package: package(),
      deps: deps()
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
      {:elixir_ale, "~> 1.0"},
      {:exred_nodeprototype, "~> 0.2"},
      {:ex_doc, "~> 0.19.0", only: :dev, runtime: false},
      {:exred_nodetest, "~> 0.1.0", only: :test}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Zsolt Keszthelyi"],
      links: %{
        "GitHub" => "https://github.com/exredorg/exred_node_picar.git",
        "Exred" => "http://exred.org"
      },
      files: ["lib", "mix.exs", "README.md", "LICENSE", "VERSION"]
    }
  end
end
