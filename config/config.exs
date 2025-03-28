import Config

config :def_deps,
  only_default_impl: false,
  mock_postfix: "Mock"

import_config "#{config_env()}.exs"
