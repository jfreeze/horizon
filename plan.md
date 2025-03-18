# Dialyzer Error Fixes

## Problem

The project has several dialyzer errors that need to be fixed:

1. `lib/horizon/nginx_config.ex:297:invalid_contract` - The @spec for `render_partial/2` doesn't match the success typing.
   - Current success typing: `@spec render_partial(String.t(), map()) :: String.t()`

2. `lib/horizon/ops/bsd/step.ex:17:7:no_return` - Function `setup/1` has no local return.

3. `lib/horizon/ops/bsd/step.ex:56:7:no_return` - Function `setup_rcd/1` has no local return.

4. `lib/horizon/simple_nginx_formatter.ex:112:8:pattern_match` - The pattern `[]` can never match the type `[binary(), ...]`.

## Solution

We'll fix each error by examining the code and making the necessary changes:

1. For the invalid contract in `nginx_config.ex`, we'll update the @spec to match the success typing.

2. For the "no local return" errors in `step.ex`, we'll ensure the functions properly return values or handle all possible error cases.

3. For the pattern match error in `simple_nginx_formatter.ex`, we'll fix the pattern matching to handle the correct type.

## Implementation Steps

- [x] Examine `lib/horizon/nginx_config.ex` and fix the @spec for `render_partial/2`
- [x] Examine `lib/horizon/ops/bsd/step.ex` and fix the `setup/1` function
- [x] Examine `lib/horizon/ops/bsd/step.ex` and fix the `setup_rcd/1` function
- [x] Examine `lib/horizon/simple_nginx_formatter.ex` and fix the pattern matching issue
- [ ] Run dialyzer to verify all errors are fixed
- [ ] Commit changes

## Status

Not started
