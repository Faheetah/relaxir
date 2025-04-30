# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of
# Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20210902-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.14.4-erlang-25.0.2-debian-bullseye-20210902-slim
#

FROM debian:bullseye-slim as builder

ENV PATH "$PATH:/root/.asdf/shims/:/asdf/bin/"
ENV MIX_ENV="prod"

# install build dependencies
RUN apt-get update -y \
    && apt-get install -y build-essential procps autoconf libssh-dev libncurses5-dev git curl unzip locales \
    && apt-get clean  \
    && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN git clone https://github.com/asdf-vm/asdf.git /asdf
RUN /asdf/bin/asdf plugin add erlang
RUN /asdf/bin/asdf install erlang 26.2.5.2
RUN /asdf/bin/asdf global erlang 26.2.5.2

RUN /asdf/bin/asdf plugin add elixir
RUN /asdf/bin/asdf install elixir 1.17.3
RUN /asdf/bin/asdf global elixir 1.17.3

RUN /asdf/bin/asdf plugin add nodejs
RUN /asdf/bin/asdf install nodejs 18.19.0
RUN /asdf/bin/asdf global nodejs 18.19.0

# prepare build dir
WORKDIR /app

# # install hex + rebar
RUN mix local.hex --force \
    && mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY lib lib
COPY priv priv

# Compile the release

RUN mix compile

# note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation
# step down so that `lib` is available.
COPY assets assets

# compile assets
RUN mix phx.digest.clean --all
RUN mix esbuild default
RUN mix assets.deploy

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM debian:bullseye-slim

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales graphicsmagick \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/prod/rel/relaxir ./

USER root

CMD ["/app/bin/server"]
