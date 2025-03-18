# Environment File Path Configuration

## Problem

When users use environment variables with `Application.compile_env`, two issues are introduced to the build chain:

1. The values are required for compiling the app
2. Changing the value of an env var causes compilation to fail

The current implementation in `build_script.sh.eex` has a hard-coded path to the environment file:

```sh
. rel/overlays/.env
MIX_ENV=prod mix deps.clean <%= @app %> --build
```

This is inflexible and doesn't allow for different environment file paths for different releases or environments.

## Solution

We've implemented a solution that allows specifying a custom environment file path in the release configuration:

1. Added a new `setup_env/2` function to the `Horizon.Ops.BSD.Step` module that:
   - Takes a release and an optional env_path parameter (defaulting to "rel/overlays/.env")
   - Stores the env_path in the release options
   - Returns the updated release config

2. Updated the `assigns/2` function in the `Horizon.Ops.BSD.Utils` module to include the `env_path` in the assigns map

3. Modified the build script template to use the `env_path` from the release options

4. Updated the `setup/1` function to include the `setup_env/1` function in the chain of steps

## Usage

### Default Usage

The default behavior remains the same, sourcing the environment file from "rel/overlays/.env". This is now handled by the `setup_env/1` function which is called by the `setup/1` function.

### Custom Environment File Path

To specify a custom environment file path, you can use the `setup_env/2` function in your release steps:

```elixir
# In mix.exs
def project do
  [
    app: :my_app,
    # ...
    releases: [
      my_app: [
        # ...
        steps: [
          &Horizon.Ops.BSD.Step.setup/1,
          &(Horizon.Ops.BSD.Step.setup_env(&1, "path/to/custom/env")),
          :assemble,
          :tar
        ]
      ]
    ]
  ]
end
```

This will configure the release to use the environment file at "path/to/custom/env" instead of the default "rel/overlays/.env".

## Implementation Details

- The `setup_env/2` function is added to the `Horizon.Ops.BSD.Step` module
- The function takes a release and an optional env_path parameter (defaulting to "rel/overlays/.env")
- The env_path is stored in the release options
- The `assigns/2` function in the `Horizon.Ops.BSD.Utils` module is updated to include the env_path in the assigns map
- The build script template is modified to use the env_path from the release options
- The `setup/1` function is updated to include the `setup_env/1` function in the chain of steps

## Status

- [x] Add `setup_env/2` function to `Horizon.Ops.BSD.Step` module
- [x] Update module documentation
- [x] Update `assigns/2` function in `Horizon.Ops.BSD.Utils` module
- [x] Modify build script template
- [x] Update `setup/1` function
