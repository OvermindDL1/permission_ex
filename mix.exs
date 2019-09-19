defmodule PermissionEx.Mixfile do
  use Mix.Project

  @description """
    Permission management and checking library for Elixir.
  """

  def project do
    [ app: :permission_ex,
      version: "0.6.0",
      description: @description,
      package: package(),
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      source_url: "https://github.com/OvermindDL1/permission_ex",
      #homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
      docs: [
        extras: ["README.md"],
        main: "readme"
        ],
      dialyzer: [
        #plt_add_apps: [:plug],
        #flags: ["-Wno_undefined_callbacks"]
        ],
      deps: deps(),
      ]
  end

  defp package do
    [ licenses: ["MIT"],
      name: :permission_ex,
      maintainers: ["OvermindDL1"],
      links: %{"Github" => "https://github.com/OvermindDL1/permission_ex"} ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [ {:credo, "~> 0.3", only: [:dev], runtime: false},
      {:dialyxir, "~> 0.3", only: [:dev], runtime: false},
      #{:earmark, "~> 0.2.1", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.20.0", only: [:dev], runtime: false},
      # {:poison, "~> 2.0"},
    ]
  end
end
