defmodule Horizon.Ops.Utils.Test do
  use ExUnit.Case

  import Bitwise
  import ExUnit.CaptureIO

  setup do
    {tmp_dir, _} = System.cmd("mktemp", ["-d"])
    {tmp_file, _} = System.cmd("mktemp", [])
    %{tmp_dir: String.trim(tmp_dir), tmp_file: String.trim(tmp_file)}
  end

  describe "safe_write/4" do
    test "creates a new file when it does not exist", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, "test_file.txt")
      data = "Sample data"

      output =
        capture_io(fn ->
          assert :ok = Horizon.Ops.Utils.safe_write(data, file, true)
        end)

      assert File.exists?(file)
      assert File.read!(file) == data
      assert output =~ "Created #{file}"
    end

    test "overwrites the file when it exists and overwrite is true", %{tmp_file: tmp_file} do
      data = "Sample data"

      output =
        capture_io(fn ->
          assert :ok = Horizon.Ops.Utils.safe_write(data, tmp_file, true)
        end)

      assert File.exists?(tmp_file)
      assert File.read!(tmp_file) == data
      assert output =~ "Overwrote #{tmp_file}"
    end

    test "safe_write/4 prompts and overwrites when user agrees", %{tmp_file: tmp_file} do
      initial_data = "Initial data"
      new_data = "New data"

      File.write!(tmp_file, initial_data)

      output =
        capture_io([input: "y\n"], fn ->
          Horizon.Ops.Utils.safe_write(new_data, tmp_file, false)
        end)

      assert output =~ "#{tmp_file} already exists. Overwrite? [y/N]"
      assert output =~ "Overwrote #{tmp_file}"
      assert File.read!(tmp_file) == new_data
    end

    test "safe_write/4 prompts and skips when user disagrees", %{tmp_file: tmp_file} do
      initial_data = "Initial data"
      new_data = "New data"

      File.write!(tmp_file, initial_data)

      output =
        capture_io([input: "n\n"], fn ->
          Horizon.Ops.Utils.safe_write(new_data, tmp_file, false)
        end)

      assert output =~ "#{tmp_file} already exists. Overwrite? [y/N]"
      assert output =~ "Skipped #{tmp_file}"
      assert File.read!(tmp_file) == initial_data
    end

    test "sets executable permission when specified", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, "test_file.sh")
      data = "#!/bin/bash\necho 'Hello World'"

      output =
        capture_io(fn ->
          Horizon.Ops.Utils.safe_write(data, file, false, true)
        end)

      assert File.exists?(file)
      assert File.read!(file) == data
      assert (File.stat!(file).mode &&& 0o111) != 0
      assert output =~ "Created #{file}"
    end

    test "handles write errors gracefully", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, "readonly_file.txt")
      data = "Sample data"

      # Create a file and make it read-only
      File.write!(file, "Existing data")
      File.chmod!(file, 0o444)

      output =
        capture_io(:stderr, fn ->
          Horizon.Ops.Utils.safe_write(data, file, true)
        end)

      assert output =~ "Failed to write to #{file}"
      assert File.read!(file) == "Existing data"
    end
  end

  describe "safe_copy_file/4" do
    test "copies the file when target does not exist", %{tmp_dir: tmp_dir} do
      source = Path.join(tmp_dir, "source_file.txt")
      target = Path.join(tmp_dir, "target_file.txt")
      File.write!(source, "Sample data")

      output =
        capture_io(fn ->
          Horizon.Ops.Utils.safe_copy_file(source, target, false)
        end)

      assert File.exists?(target)
      assert File.read!(target) == "Sample data"
      assert output =~ "\e[32mCreated   \e[0m#{target}"
    end

    test "overwrites the file when overwrite is true", %{tmp_dir: tmp_dir} do
      source = Path.join(tmp_dir, "source_file.txt")
      target = Path.join(tmp_dir, "target_file.txt")
      File.write!(source, "New data")
      File.write!(target, "Old data")

      output =
        capture_io(fn ->
          Horizon.Ops.Utils.safe_copy_file(source, target, true)
        end)

      assert File.read!(target) == "New data"
      assert output =~ "\e[33mOverwrote \e[0m#{target}"
    end

    test "prompts and overwrites when user agrees", %{tmp_dir: tmp_dir} do
      source = Path.join(tmp_dir, "source_file.txt")
      target = Path.join(tmp_dir, "target_file.txt")
      File.write!(source, "New data")
      File.write!(target, "Old data")

      # Mock Mix.shell to simulate user input
      Mix.shell(Mix.Shell.Process)
      send(self(), {:mix_shell_input, :yes?, true})

      Horizon.Ops.Utils.safe_copy_file(source, target, false)

      # Assert that the prompt was sent
      assert_received {:mix_shell, :yes?, [message]}
      assert message == "#{target} already exists. Overwrite? [y/N]"

      # Assert that the info message was sent
      assert_received {:mix_shell, :info, [info_message]}
      assert info_message == "Overwrote #{target}"

      # Assert that the file content was updated
      assert File.read!(target) == "New data"

      # Reset Mix.shell
      Mix.shell(Mix.Shell.IO)
    end

    test "prompts and skips when user declines", %{tmp_dir: tmp_dir} do
      source = Path.join(tmp_dir, "source_file.txt")
      target = Path.join(tmp_dir, "target_file.txt")
      File.write!(source, "New data")
      File.write!(target, "Old data")

      # Mock Mix.shell to simulate user input
      Mix.shell(Mix.Shell.Process)
      send(self(), {:mix_shell_input, :yes?, false})

      Horizon.Ops.Utils.safe_copy_file(source, target, false)

      # Assert that the prompt was sent
      assert_received {:mix_shell, :yes?, [message]}
      assert message == "#{target} already exists. Overwrite? [y/N]"

      # Assert that the info message was sent
      assert_received {:mix_shell, :info, [info_message]}
      assert info_message == "Skipped #{target}"

      # Assert that the file content remains unchanged
      assert File.read!(target) == "Old data"

      # Reset Mix.shell
      Mix.shell(Mix.Shell.IO)
    end

    test "handles missing source file gracefully", %{tmp_dir: tmp_dir} do
      source = Path.join(tmp_dir, "non_existent_source.txt")
      target = Path.join(tmp_dir, "target_file.txt")

      output =
        capture_io(:stderr, fn ->
          Horizon.Ops.Utils.safe_copy_file(source, target, false)
        end)

      assert output =~ "Failed to copy #{target}"
      refute File.exists?(target)
    end

    test "sets executable permission when specified", %{tmp_dir: tmp_dir} do
      source = Path.join(tmp_dir, "source_script.sh")
      target = Path.join(tmp_dir, "target_script.sh")
      File.write!(source, "#!/bin/bash\necho 'Hello World'")

      output =
        capture_io(fn ->
          Horizon.Ops.Utils.safe_copy_file(source, target, false, true)
        end)

      assert File.exists?(target)
      assert File.read!(target) == "#!/bin/bash\necho 'Hello World'"
      assert (File.stat!(target).mode &&& 0o111) != 0
      assert output =~ "\e[32mCreated   \e[0m#{target}"
    end
  end
end
