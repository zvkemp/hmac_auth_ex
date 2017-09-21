defmodule HMACAuth.MixProject do
  use Mix.Project

  def project do
    [app: :hmac_auth_ex,
     version: "0.3.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     description: description(),
     source_url: github_url()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
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
    [
      {:plug, "~> 1.3"},
      {:dialyxir, "~> 0.5", only: :dev, runtime: :false}
    ]
  end

  defp description do
    "One-time token (shared secret) HTTP authorization with TTL"
  end

  defp github_url do
   "https://github.com/zvkemp/hmac_auth_ex"
  end

  defp package do
    [
      maintainers: ["Zach Kemp"],
      licenses: ["MIT"],
      links: %{"GitHub" => github_url()}
    ]
  end
end
