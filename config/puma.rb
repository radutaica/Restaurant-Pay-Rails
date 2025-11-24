# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
# Increased thread count to handle SSE connections
# Each SSE connection uses 1 thread, so we need more threads available
# This allows multiple SSE connections while still having threads for regular requests
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 20 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { 5 }
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
#
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Specifies the `port`/binding that Puma will listen on to receive requests.
#
if ENV.fetch("RAILS_ENV", "development") == "development"
  ssl_port = ENV.fetch("SSL_PORT", 3001)
  ssl_bind "127.0.0.1", ssl_port, {
    key:  File.expand_path("ssl/localhost.key", __dir__),
    cert: File.expand_path("ssl/localhost.crt", __dir__),
    verify_mode: "none"
  }
else
  port ENV.fetch("PORT") { 3000 }
end

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
# preload_app!

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Handle shutdown signals gracefully even with long-running connections
on_worker_shutdown do
  Rails.logger.info "Puma worker shutting down..."
end

# Force shutdown after timeout (helps with Ctrl+C when SSE connections are active)
force_shutdown_after 5 # seconds
