# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

# AI API configuration for receipt scanning (applies to all environments)
config :relaxir, :ai_api_endpoint, System.get_env("AI_API_ENDPOINT")
config :relaxir, :ai_api_key, System.get_env("AI_API_KEY")
config :relaxir, :ai_model, System.get_env("AI_MODEL")

if config_env() == :prod do
  config :relaxir, Relaxir.Repo,
    url: System.fetch_env!("DATABASE_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :relaxir, RelaxirWeb.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

  config :relaxir, RelaxirWeb.Endpoint, server: true

  config :relaxir, RelaxirWeb.UploadLive, dest: System.fetch_env!("RELAXIR_UPLOAD_PATH") || "/tmp/uploads"
end
