FROM hexpm/elixir:1.11.1-erlang-23.1.1-ubuntu-bionic-20200630

RUN apt-get update && apt-get -y install curl
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

# Create the application build directory
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

# Fetch dependencies
COPY mix.exs .
COPY mix.lock .
COPY config/config.exs ./config/
COPY config/prod.exs ./config/
COPY config/runtime.exs ./config/
RUN mix deps.get --only prod
RUN mix deps.compile

# Install / update  JavaScript dependencies
COPY assets/css ./assets/css
COPY assets/js ./assets/js
COPY assets/static ./assets/static
COPY assets/.babelrc ./assets/
COPY assets/package-lock.json ./assets/
COPY assets/package.json ./assets/
COPY assets/webpack.config.js ./assets/
COPY priv/gettext ./priv/
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets


# Compile
COPY lib ./lib
COPY rel ./rel
RUN mix phx.digest
RUN mix compile

CMD ["mix", "release", "--overwrite"]