[
  {"lib/horizon/ops/utils.ex", :unknown_function, 67},
  {"lib/horizon/nginx_config_generator.ex", :unknown_function, 28},
  # Ignore all unknown functions related to Mix.shell/0 and Mix.Project.config/0
  ~r"lib/horizon/ops/utils.ex:\d+:unknown_function Function Mix.shell/0 does not exist",
  ~r"lib/horizon/ops/bsd/utils.ex:\d+:unknown_function Function Mix.shell/0 does not exist",
  ~r"lib/horizon/ops/utils.ex:\d+:unknown_function Function Mix.Project.config/0 does not exist",
  ~r"lib/horizon/ops/bsd/utils.ex:\d+:unknown_function Function Mix.Project.config/0 does not exist",
  ~r"lib/mix/tasks/horizon/bsd/init.ex:\d+:unknown_function Function Mix.Project.config/0 does not exist",

  # Ignore no_return warnings in horizon/step.ex
  ~r"lib/horizon/ops/bsd/step.ex:\d+:no_return",

  # Ignore unknown type Mix.Release.t/0 warnings
  ~r"lib/horizon/ops/bsd/step.ex:\d+:\d+:unknown_type Unknown type: Mix.Release.t/0",
  ~r"lib/horizon/ops/bsd/config.ex:\d+:\d+:unknown_type Unknown type: Mix.Release.t/0",

  # Ignore callback info missing for Mix.Task behavior
  ~r"lib/mix/tasks/horizon/bsd/init.ex:\d+:callback_info_missing"
]
#lib/horizon/ops/utils.ex:67:unknown_function
#EEx.eval_string/2
