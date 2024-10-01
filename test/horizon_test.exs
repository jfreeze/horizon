defmodule HorizonTest do
  use ExUnit.Case

  import Bitwise
  import ExUnit.CaptureIO

  alias Horizon

  describe "safe_write/4" do
    setup do
      {tmp_dir, _} = System.cmd("mktemp", ["-d"])
      {tmp_file, _} = System.cmd("mktemp", [])
      %{tmp_dir: String.trim(tmp_dir), tmp_file: String.trim(tmp_file)}
    end

    test "creates a new file when it does not exist", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, "test_file.txt")
      data = "Sample data"

      output =
        capture_io(fn ->
          assert :ok = Horizon.safe_write(data, file, true)
        end)

      assert File.exists?(file)
      assert File.read!(file) == data
      assert output =~ "Created #{file}"
    end

    test "overwrites the file when it exists and overwrite is true", %{tmp_file: tmp_file} do
      data = "Sample data"

      output =
        capture_io(fn ->
          assert :ok = Horizon.safe_write(data, tmp_file, true)
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
          Horizon.safe_write(new_data, tmp_file, false)
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
          Horizon.safe_write(new_data, tmp_file, false)
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
          Horizon.safe_write(data, file, false, true)
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
          Horizon.safe_write(data, file, true)
        end)

      assert output =~ "Failed to write to #{file}"
      assert File.read!(file) == "Existing data"
    end
  end
end
