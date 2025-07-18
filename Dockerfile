FROM elixir:1.15

RUN apt-get update && \
    apt-get install -y ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

RUN mix compile

CMD ["mix", "phx.server"] 