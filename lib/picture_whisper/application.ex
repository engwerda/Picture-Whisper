defmodule PictureWhisper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    unless Mix.env == :prod do
      Dotenv.load
      Mix.Task.run("loadconfig")
    end

    children = [
      PictureWhisperWeb.Telemetry,
      PictureWhisper.Repo,
      {DNSCluster, query: Application.get_env(:picture_whisper, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PictureWhisper.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PictureWhisper.Finch},
      # Start a worker by calling: PictureWhisper.Worker.start_link(arg)
      # {PictureWhisper.Worker, arg},
      # Start to serve requests, typically the last entry
      PictureWhisperWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PictureWhisper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PictureWhisperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
