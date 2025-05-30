import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :relaxir, RelaxirWeb.Endpoint,
  show_sensitive_data_on_connection_error: true,
  url: [host: "www.relaxanddine.com", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

# I have no idea how to have this in runtime.exs but also not fail on compile from Application.compile_env!/3
config :relaxir, RelaxirWeb.UploadLive,
  dest: "/tmp/uploads"
