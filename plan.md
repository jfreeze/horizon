# Horizon NginxConfig Fix Plan

## Issue
The `Horizon.NginxConfig.generate` function is producing a reversed/inverted nginx configuration. The output shows the closing braces first, followed by the configuration content, which is incorrect.

## Analysis
After examining the code, the issue appears to be in the `Horizon.SimpleNginxFormatter` module. The formatter is building the accumulator in the correct order using `acc ++ [line]`, but then it's reversing the accumulator at the end with `Enum.reverse(acc)`. This is causing the nginx configuration to be generated in reverse order.

## Solution Steps
- [x] Examine the current implementation of `Horizon.NginxConfig` and `Horizon.SimpleNginxFormatter`
- [x] Identify the issue in the formatter
- [x] Fix the `do_format` function in the `Horizon.SimpleNginxFormatter` module to not reverse the accumulator at the end
- [ ] Test the fix by running the `generate` function with a sample project
- [ ] Commit the changes

## Implementation Details
The fix will involve modifying the `do_format` function in the `Horizon.SimpleNginxFormatter` module to not reverse the accumulator at the end when it's already built in the correct order.
