defmodule Horizon.NginxConfigTest do
  use ExUnit.Case

  alias Horizon.NginxConfig

  @sample_projects [
    Horizon.Project.new(name: "project1", server_names: ["www.foo.com", "foo.com"]),
    Horizon.Project.new(name: "project2")
  ]

  @template_override """
  # Overridden template
  <%= for project <- projects do %>
    <%= Horizon.NginxConfig.render_partial(:upstream, project: project) %>
    <%= Horizon.NginxConfig.render_partial(:server_http, project: project) %>
    <%= Horizon.NginxConfig.render_partial(:server_https, project: project) %>
  <% end %>
  """

  describe "Overriding template files with NginxConf.generate/2" do
    setup do
      # Create override directory
      root = "priv/horizon/templates"
      File.mkdir_p!("#{root}")

      override_template(root)
      File.write!("#{root}/_upstream.eex", "upstream <%= project.name %>")

      File.write!(
        "#{root}/_server_http.eex",
        "server_http <%= project.name %>"
      )

      File.write!(
        "#{root}/_server_https.eex",
        "server_https <%= project.name %>"
      )

      # Ensure files are cleaned up after the test
      on_exit(fn ->
        File.rm_rf!("priv/horizon")
      end)

      :ok
    end

    defp override_template(root) do
      # Write the overridden main template
      File.write!("#{root}/nginx.conf.eex", @template_override)
    end

    test "outputs the correct nginx config" do
      config = NginxConfig.generate(@sample_projects)
      # Assert the config contains expected content from override
      assert config_matches?(config, [
               "# Overridden template",
               "upstream project1",
               "server_http project1",
               "server_https project1",
               "upstream project2",
               "server_http project2",
               "server_https project2"
             ])
    end
  end

  describe "NginxConf.generate/2" do
    test "uses default options when none provided" do
      project = Horizon.Project.new(name: "test_project")
      config = NginxConfig.generate([project])

      assert config_matches?(config, [
               "worker_connections 1024;",
               "client_max_body_size 6M;",
               "sendfile on;",
               "keepalive_timeout 65;",
               "gzip on;",
               "access_log on;",
               "access_log /var/log/nginx/access.log;"
             ])
    end

    test "accepts custom options" do
      project = Horizon.Project.new(name: "test_project")

      config =
        NginxConfig.generate([project],
          client_max_body_size: "20M",
          sendfile: false,
          keepalive_timeout: 120,
          gzip: false,
          access_log: false,
          worker_connections: 2048
        )

      assert config_matches?(config, [
               "worker_connections 2048;",
               "client_max_body_size 20M;",
               "sendfile off;",
               "keepalive_timeout 120;",
               "gzip off;",
               "access_log off;"
             ])

      refute config =~ "access_log /var/log/nginx/access.log"
    end

    test "merges partial options with defaults" do
      project = Horizon.Project.new(name: "test_project")

      config =
        NginxConfig.generate([project],
          client_max_body_size: "15M",
          gzip: false
        )

      assert config_matches?(config, [
               "worker_connections 1024;",
               "client_max_body_size 15M;",
               "sendfile on;",
               "keepalive_timeout 65;",
               "gzip off;",
               "access_log on;",
               "access_log /var/log/nginx/access.log;"
             ])
    end

    test "with multiple servers, http_only: true" do
      projects = [
        %Horizon.Project{
          name: "project1",
          server_names: ["server1", "server2"],
          http_only: true,
          servers: [
            %Horizon.Server{internal_ip: "1.2.3.4", port: 4321},
            %Horizon.Server{internal_ip: "4.3.2.1", port: 4321}
          ]
        }
      ]

      upstream_block = [
        "upstream backend_project1 {",
        "ip_hash;",
        "server 1.2.3.4:4321;",
        "server 4.3.2.1:4321;"
      ]

      http_block = [
        "server {",
        "listen 80;",
        "server_name server1 server2;",
        "location / {",
        "proxy_pass http://backend_project1;",
        "proxy_http_version 1.1;",
        "proxy_set_header Upgrade $http_upgrade;",
        "proxy_set_header Connection $connection_upgrade;",
        "proxy_set_header Host $host;",
        "proxy_set_header X-Real-IP $remote_addr;",
        "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
      ]

      config = NginxConfig.generate(projects)

      assert config_matches?(config, upstream_block)
      assert config_matches?(config, http_block)
      refute config =~ "listen 443 ssl;"
    end

    test "with multiple servers and acme_challenge_path" do
      projects = [
        %Horizon.Project{
          name: "project1",
          server_names: ["server1", "server2"],
          certificate: :letsencrypt,
          acme_challenge_path: "/usr/local/project1",
          servers: [
            %Horizon.Server{internal_ip: "1.2.3.4", port: 4321},
            %Horizon.Server{internal_ip: "4.3.2.1", port: 4321}
          ]
        }
      ]

      upstream_block = [
        "upstream backend_project1 {",
        "ip_hash;",
        "server 1.2.3.4:4321;",
        "server 4.3.2.1:4321;"
      ]

      http_block = [
        "server {",
        "listen 80;",
        "server_name server1 server2;",
        "location / {",
        "proxy_pass http://backend_project1;",
        "proxy_http_version 1.1;",
        "proxy_set_header Upgrade $http_upgrade;",
        "proxy_set_header Connection $connection_upgrade;",
        "proxy_set_header Host $host;",
        "proxy_set_header X-Real-IP $remote_addr;",
        "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
      ]

      https_block = [
        "server {",
        "listen 443 ssl;",
        "server_name server1 server2;",
        "ssl_protocols TLSv1.2 TLSv1.3;",
        "ssl_ciphers HIGH:!aNULL:!MD5;",
        "ssl_certificate ;",
        "ssl_certificate_key ;",
        "location / {",
        "proxy_pass http://backend_project1;",
        "proxy_http_version 1.1;",
        "proxy_set_header Upgrade $http_upgrade;",
        "proxy_set_header Connection $connection_upgrade;",
        "proxy_set_header Host $host;",
        "proxy_set_header X-Real-IP $remote_addr;",
        "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
      ]

      config = NginxConfig.generate(projects)
      assert config_matches?(config, upstream_block)
      assert config_matches?(config, http_block)
      assert config_matches?(config, https_block)
    end

    test "skips upstream block when servers list is empty" do
      project =
        Horizon.Project.new(
          name: "no_servers",
          server_names: ["example.com"],
          http_only: true
        )

      config = NginxConfig.generate([project])

      refute config =~ "upstream backend_no_servers"
      refute config =~ "ip_hash;"
      assert config =~ "server_name example.com;"
    end

    test "properly formats http only project" do
      project =
        Horizon.Project.new(
          name: "my_project",
          server_names: ["my-domain.com", "also-mine.io"],
          http_only: true,
          servers: [
            %Horizon.Server{internal_ip: "127.0.0.1", port: 4000}
          ]
        )

      upstream_block = [
        "upstream backend_my_project {",
        "ip_hash;",
        "server 127.0.0.1:4000;"
      ]

      http_block = [
        "server {",
        "listen 80;",
        "server_name my-domain.com also-mine.io;",
        "# HTTP only. Route traffic to proxy.",
        "location / {",
        "proxy_pass http://backend_my_project;",
        "proxy_http_version 1.1;",
        "proxy_set_header Upgrade $http_upgrade;",
        "proxy_set_header Connection $connection_upgrade;",
        "proxy_set_header Host $host;",
        "proxy_set_header X-Real-IP $remote_addr;",
        "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
        "}",
        "}"
      ]

      config = NginxConfig.generate([project])

      assert config_matches?(config, upstream_block)
      assert config_matches?(config, http_block)
      refute config =~ "listen 443 ssl;"
    end

    test "properly formats letsencrypt challenge configuration" do
      project =
        Horizon.Project.new(
          name: "my_project",
          server_names: ["my-domain.com"],
          http_only: false,
          acme_challenge_path: "/var/www/acme",
          certificate: :letsencrypt,
          letsencrypt_domain: "my-domain.com"
        )

      config = NginxConfig.generate([project])

      http_block = [
        "server {",
        "listen 80;",
        "server_name my-domain.com;",
        "location ^~ /.well-known/acme-challenge/ {",
        "alias /var/www/acme/.well-known/acme-challenge/;",
        "}",
        "location = /.well-known/acme-challenge/ {",
        "return 404;",
        "}",
        "# Serving HTTPS, so redirect from HTTP to HTTPS.",
        "location / {",
        "return 301 https://$host$request_uri;",
        "}",
        "}"
      ]

      assert config_matches?(config, http_block)
    end

    test "properly formats static index for project" do
      project =
        Horizon.Project.new(
          name: "static_site",
          server_names: ["static.example.com"],
          static_index_root: "/var/www/static",
          static_index: "index.html"
        )

      config = NginxConfig.generate([project])

      https_block = [
        "server {",
        "listen 443 ssl;",
        "server_name static.example.com;",
        "ssl_protocols TLSv1.2 TLSv1.3;",
        "ssl_ciphers HIGH:!aNULL:!MD5;",
        "root /var/www/static;",
        "index index.html;",
        "location / {",
        "try_files $uri /index.html;",
        "}"
      ]

      assert config_matches?(config, https_block)
    end

    test "properly formats static index for http project" do
      project =
        Horizon.Project.new(
          name: "static_site",
          server_names: ["static.example.com"],
          http_only: true,
          static_index_root: "/var/www/static",
          static_index: "index.html"
        )

      config = NginxConfig.generate([project])

      http_block = [
        "server {",
        "listen 80;",
        "server_name static.example.com;",
        "root /var/www/static;",
        "index index.html;",
        "location / {",
        "try_files $uri /index.html;",
        "}",
        "}"
      ]

      assert config_matches?(config, http_block)
    end

    test "properly configures self-signed certificates on static pages" do
      project =
        Horizon.Project.new(
          name: "self_signed_app",
          server_names: ["secure.example.com"],
          certificate: :self,
          cert_path: "/path/to/cert.pem",
          cert_key_path: "/path/to/key.pem",
          static_index_root: "/var/www/static",
          static_index: "index.html"
        )

      config = NginxConfig.generate([project])

      https_block = [
        "server {",
        "listen 443 ssl;",
        "server_name secure.example.com;",
        "ssl_protocols TLSv1.2 TLSv1.3;",
        "ssl_ciphers HIGH:!aNULL:!MD5;",
        "ssl_certificate /path/to/cert.pem;",
        "ssl_certificate_key /path/to/key.pem;",
        "root /var/www/static;",
        "index index.html;",
        "location / {",
        "try_files $uri /index.html;",
        "}",
        "}"
      ]

      assert config_matches?(config, https_block)
    end

    test "properly configures self-signed certificates" do
      project =
        Horizon.Project.new(
          name: "self_signed_app",
          server_names: ["secure.example.com"],
          certificate: :self,
          cert_path: "/path/to/cert.pem",
          cert_key_path: "/path/to/key.pem",
          servers: [
            %Horizon.Server{internal_ip: "127.0.0.1", port: 4000}
          ]
        )

      config = NginxConfig.generate([project])

      https_block = [
        "server {",
        "listen 443 ssl;",
        "server_name secure.example.com;",
        "ssl_protocols TLSv1.2 TLSv1.3;",
        "ssl_ciphers HIGH:!aNULL:!MD5;",
        "ssl_certificate /path/to/cert.pem;",
        "ssl_certificate_key /path/to/key.pem;",
        "}"
      ]

      assert config_matches?(config, https_block)
    end

    test "properly formats http/https project" do
      project =
        Horizon.Project.new(
          name: "secure_app",
          server_names: ["secure.example.com"],
          http_only: false,
          certificate: :self,
          cert_path: "/etc/certs/secure.pem",
          cert_key_path: "/etc/certs/secure.key",
          servers: [
            %Horizon.Server{internal_ip: "127.0.0.1", port: 4000}
          ]
        )

      config = NginxConfig.generate([project])

      upstream_block = [
        "ip_hash;",
        "server 127.0.0.1:4000;"
      ]

      http_block = [
        "listen 80;",
        "server_name secure.example.com;",
        "# Serving HTTPS, so redirect from HTTP to HTTPS.",
        "location / {",
        "return 301 https://$host$request_uri;"
      ]

      https_block = [
        "listen 443 ssl;",
        "server_name secure.example.com;",
        "ssl_protocols TLSv1.2 TLSv1.3;",
        "ssl_ciphers HIGH:!aNULL:!MD5;",
        "ssl_certificate /etc/certs/secure.pem;",
        "ssl_certificate_key /etc/certs/secure.key;",
        "location / {",
        "proxy_pass http://backend_secure_app;",
        "proxy_http_version 1.1;",
        "proxy_set_header Upgrade $http_upgrade;",
        "proxy_set_header Connection $connection_upgrade;",
        "proxy_set_header Host $host;",
        "proxy_set_header X-Real-IP $remote_addr;",
        "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
      ]

      config_matches?(config, upstream_block)
      config_matches?(config, http_block)
      config_matches?(config, https_block)
    end
  end

  def config_matches?(config, expected_lines) do
    config_lines =
      config
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    # Find all occurrences of each line
    line_positions =
      expected_lines
      |> Enum.map(fn expected ->
        indices =
          config_lines
          |> Enum.with_index()
          |> Enum.filter(fn {line, _idx} -> line == String.trim(expected) end)
          |> Enum.map(fn {_line, idx} -> idx end)

        {expected, indices}
      end)

    # Try to find a valid sequence
    case find_ordered_sequence(line_positions) do
      nil ->
        missing_lines =
          line_positions
          |> Enum.filter(fn {_, indices} -> indices == [] end)
          |> Enum.map(fn {line, _} -> "Line not found: #{line}" end)

        flunk("""
        Config matching failed:
        #{Enum.join(missing_lines, "\n")}

        Full config:
        #{config}

        Expected lines in order:
        #{Enum.join(expected_lines, "\n")}
        """)

      _sequence ->
        true
    end
  end

  # Recursively try to find a valid sequence of increasing indices
  defp find_ordered_sequence([]), do: []
  defp find_ordered_sequence([{_line, []} | _]), do: nil

  defp find_ordered_sequence([{_line, indices} | rest]) do
    Enum.find_value(indices, fn idx ->
      case find_ordered_sequence_from(rest, idx) do
        nil -> nil
        rest_sequence -> [idx | rest_sequence]
      end
    end)
  end

  defp find_ordered_sequence_from([], _prev_idx), do: []
  defp find_ordered_sequence_from([{_line, []} | _rest], _prev_idx), do: nil

  defp find_ordered_sequence_from([{_line, indices} | rest], prev_idx) do
    # Find the first valid index after prev_idx
    valid_indices = Enum.filter(indices, &(&1 > prev_idx))

    case valid_indices do
      [] ->
        nil

      [next_idx | _] ->
        case find_ordered_sequence_from(rest, next_idx) do
          nil -> nil
          rest_sequence -> [next_idx | rest_sequence]
        end
    end
  end
end
