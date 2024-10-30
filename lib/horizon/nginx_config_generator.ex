defmodule Horizon.NginxConfig do
  @moduledoc """
  Generates an Nginx configuration file using a templating system.
  Allows for template overrides in the current project.
  The configuration is based on Horizon.Project and Horizon.Server.

  """

  # @default_template_path "priv/horizon/templates/nginx.conf.eex"
  @default_template_path Path.join([__DIR__, "../../priv/templates/nginx/nginx.conf.eex"])
                         |> Path.expand()

  @spec generate([Horizon.Project.t()]) :: :ok
  def generate(projects) when is_list(projects) do
    app_name = current_app_name()

    project_template_path =
      Path.join([:code.priv_dir(app_name), "horizon/templates/nginx.conf.eex"])

    template_path =
      if File.exists?(project_template_path) do
        project_template_path
      else
        @default_template_path
      end

    template_path
    |> File.read!()
    |> EEx.eval_string(projects: projects)
    |> IO.puts()
  end

  # Dynamically get the current application name
  defp current_app_name do
    case Application.get_application(__MODULE__) do
      nil -> raise "ERROR: Could not determine the current application name"
      app -> app
    end
  end
end
