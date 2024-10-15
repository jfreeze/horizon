[
  {"lib/horizon.ex", :unknown_function, 64},
  # Ignore all unknown functions related to Mix.shell/0 and Mix.Project.config/0
  ~r"lib/horizon.ex:\d+:unknown_function Function Mix.shell/0 does not exist",
  ~r"lib/horizon.ex:\d+:unknown_function Function Mix.Project.config/0 does not exist",
  ~r"lib/mix/tasks/horizon/init.ex:\d+:unknown_function Function Mix.Project.config/0 does not exist",

  # Ignore no_return warnings in horizon/step.ex
  ~r"lib/horizon/step.ex:\d+:no_return",

  # Ignore unknown type Mix.Release.t/0 warnings
  ~r"lib/horizon/step.ex:\d+:\d+:unknown_type Unknown type: Mix.Release.t/0",
  ~r"lib/horizon/config.ex:\d+:\d+:unknown_type Unknown type: Mix.Release.t/0",

  # Ignore callback info missing for Mix.Task behavior
  ~r"lib/mix/tasks/horizon/init.ex:\d+:callback_info_missing"
]
