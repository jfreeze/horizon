defmodule Horizon.SimpleNginxFormatter do
  @indent_size 2

  @doc """
  Formats an nginx.conf-like string with proper indentation and spacing.

  Formatting includes:
    - Indenting lines based on '{' and '}'.
    - Inserting a blank line before a line containing '{'
      unless the previous line is blank or a comment.
    - Inserting a blank line after a line containing '}'
      unless the next line is also a closing brace ('}').
  """
  def format(conf) do
    lines =
      conf
      |> String.split(~r/\r?\n/)
      |> Enum.map(&String.trim/1)
      # Optionally remove empty lines from original input:
      |> Enum.reject(&(&1 == ""))

    do_format(lines, 0, [])
    |> Enum.join("\n")
  end

  # When there's no more input lines, we're done.
  defp do_format([], _current_indent, acc), do: acc

  # When there's exactly one line left, handle it (with no "look ahead").
  defp do_format([line], current_indent, acc) do
    {new_acc, _new_indent} = handle_line(line, current_indent, acc, nil)
    new_acc
  end

  # When there's at least two lines, we can "look ahead" at `next_line`.
  defp do_format([line, next_line | rest], current_indent, acc) do
    {acc, new_indent} = handle_line(line, current_indent, acc, next_line)
    # Now recurse, treating `next_line` as the next "current" line.
    do_format([next_line | rest], new_indent, acc)
  end

  # This function handles a single line, with knowledge of:
  #  - current indentation
  #  - the accumulated output so far
  #  - the "look-ahead" next line (which might be nil if there's no next line)
  defp handle_line(line, current_indent, acc, next_line) do
    # 1) If this line has '}', we reduce indentation first
    indent_now =
      if closing_brace?(line) do
        max(current_indent - 1, 0)
      else
        current_indent
      end

    # 2) If this line opens a block, maybe insert a blank line unless
    #    the previous line was blank or a comment
    acc =
      if opening_brace?(line) do
        maybe_insert_blank_line_unless_comment(acc)
      else
        acc
      end

    # 3) Add the line (indented)
    acc = add_line(acc, line, indent_now)

    # 4) If this line closes a block, add a blank line unless the next line
    #    is also a closing brace
    acc =
      if closing_brace?(line) and not next_line_closes_block?(next_line) do
        maybe_insert_blank_line(acc)
      else
        acc
      end

    # 5) If the line opens a block, increase indentation for subsequent lines
    new_indent =
      if opening_brace?(line) do
        indent_now + 1
      else
        indent_now
      end

    {acc, new_indent}
  end

  # --- Helpers ---

  defp opening_brace?(line), do: String.contains?(line, "{")
  defp closing_brace?(line), do: String.contains?(line, "}")

  # Check if the "look-ahead" line (if any) is effectively just a closing brace.
  # This is naive: if the next line is `nil`, we treat it as not closing.
  defp next_line_closes_block?(nil), do: false
  defp next_line_closes_block?(line), do: closing_brace?(line)

  # Possibly insert a blank line unless the previous line is
  # already blank or a comment (starts with #).
  defp maybe_insert_blank_line_unless_comment([]), do: []

  defp maybe_insert_blank_line_unless_comment(acc) do
    last_line = List.last(acc)

    cond do
      last_line == "" -> acc
      String.starts_with?(String.trim_leading(last_line), "#") -> acc
      true -> acc ++ [""]
    end
  end

  # Always insert a blank line if the last line isn't already blank.
  defp maybe_insert_blank_line([]), do: [""]

  defp maybe_insert_blank_line(acc) do
    case List.last(acc) do
      "" -> acc
      _ -> acc ++ [""]
    end
  end

  # Add a line with indentation.
  defp add_line(acc, line, indent_level) do
    acc ++ [indent(line, indent_level)]
  end

  defp indent(line, level) do
    String.duplicate(" ", @indent_size * level) <> line
  end
end
