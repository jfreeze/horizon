defmodule Mix.Tasks.Horizon.Gen.Cert do
  @shortdoc "Sets up SSL self-signed certificates"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    priv_cert_dir = Path.join(["priv", "cert"])
    cert_file = Path.join(priv_cert_dir, "selfsigned.pem")
    key_file = Path.join(priv_cert_dir, "selfsigned_key.pem")

    # Check if the certificate files exist; if not, generate them
    if !File.exists?(cert_file) or !File.exists?(key_file) do
      Mix.shell().info("Certificates not found. Generating certificates...")
      # Mix.Task.reenable("phx.gen.cert")
      Mix.Task.run("phx.gen.cert", [])
    end

    overlay_cert_dir = Path.join(["rel", "overlays", "cert"])

    # Create the overlays/cert directory if it doesn't exist
    unless File.dir?(overlay_cert_dir) do
      File.mkdir_p!(overlay_cert_dir)
      Mix.shell().info("Created directory #{overlay_cert_dir}")
    end

    # Copy the certificate files to the overlays/cert folder
    File.cp!(cert_file, Path.join(overlay_cert_dir, "selfsigned.pem"))
    File.cp!(key_file, Path.join(overlay_cert_dir, "selfsigned_key.pem"))
    Mix.shell().info("Copied certificate files to #{overlay_cert_dir}")

    # Change their mode to 600
    File.chmod!(Path.join(overlay_cert_dir, "selfsigned.pem"), 0o600)
    File.chmod!(Path.join(overlay_cert_dir, "selfsigned_key.pem"), 0o600)
    Mix.shell().info("Set file permissions to 600 for certificate files.")
  end
end
