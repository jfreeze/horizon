defmodule Horizon.Step do
  def echo(%Mix.Release{name: name, options: options} = release) do
    IO.puts("\u001b[32;1m  ===> running echo\u001b[0m")
    dbg(name)
    dbg(options)
    release
  end

  def setup_rcd(%Mix.Release{name: name, options: options} = release) do
    options_with_defaults = Horizon.Config.merge_defaults(options, name)
    release = Map.put(release, :options, options_with_defaults)

    file = "/usr/local/etc/rc.d/#{name}"
    dbg(System.cmd("/usr/bin/whoami", []))

    if !File.exists?(file) do
      System.cmd("/usr/local/bin/doas", ["touch", file])
      System.cmd("/usr/local/bin/doas", ["chmod", "755", file])

      Horizon.create_file_from_template(
        :rc_d,
        name,
        false,
        false,
        options_with_defaults,
        &Horizon.assigns/2,
        fn _app, _opts -> file end
      )
    end

    release
  end
end
