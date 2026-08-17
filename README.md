# Tortoise WoW (Docker)

# Safety tip: as this repo get rebuilt regularly based on original Shyalya's work, things may break, backup everything before you update!

Run a private [Turtle WoW](https://turtle-wow.org/) server with Docker. This stack uses [Shyalya/tortoise-wow](https://github.com/Shyalya/tortoise-wow) with playerbots.

The server work and install steps come from this video:

**[Tortoise WoW / playerbots setup (YouTube)](https://www.youtube.com/watch?v=CNgkHs3btNE)**

This repository ships a Compose file. CI builds and publishes the server images to GHCR. The published binaries use a portable x86-64-v2 CPU target so the image does not depend on the instruction set of the CI runner.

## What you need

- Docker Desktop (or Docker Engine with Compose v2)
- A Turtle WoW **1.18.1** client (**build 7272**)
- Client data folders: `dbc`, `maps`, `vmaps`, `mmaps`
- Several GB of free disk space

The images do not include client data. You extract that data from your game client. The video and the [Linux install guide](https://github.com/Shyalya/tortoise-wow/blob/playerbots-integration-gh/INSTALL-LINUX.md) show how.

## Quick start

### 1. Get the Compose files

```bash
git clone https://github.com/Nescabir/tortoise-docker.git
cd tortoise-docker
```

### 2. Create your settings file

```bash
cp .env.example .env
```

Edit `.env`:

1. Set strong values for `DB_ROOT_PASSWORD` and `DB_PASSWORD`.
2. Set `REALM_ADDRESS` to an address your game client can reach.
3. Set `DATA_PATH` if your client data is not in `./data`.

Use `127.0.0.1` for `REALM_ADDRESS` only when the client runs on the same machine. For another PC on your LAN, use your host LAN IP.

### 3. Add client data

Put the extracted folders here (or under your `DATA_PATH`):

```text
data/
  dbc/
  maps/
  vmaps/
  mmaps/
```

### 4. Start with Compose

Compose pulls the published images and starts the stack:

```bash
docker compose up -d
```

The first start downloads the images (if needed) and imports the world database. This takes several minutes.

Then watch the world server:

```bash
docker compose logs -f mangosd
```

Wait until the log shows:

```text
World server is up and running
```

The first start with playerbots is slow. The server builds bot gear data before it is ready. Do not create an account before that line appears.

### 5. Create a game account

```bash
docker compose exec -u turtle mangosd bash -c 'echo "account create myuser mypass" > /opt/turtle/run/mangosd.in'
```

Check that the account exists:

```bash
docker compose exec -T db mariadb -uroot -pYOUR_ROOT_PASSWORD -e "SELECT id, username FROM tw_logon.account;"
```

Replace `YOUR_ROOT_PASSWORD` with the value of `DB_ROOT_PASSWORD` from `.env`.

### 6. Connect with the client

Edit `realmlist.wtf` in your Turtle WoW client:

```text
set realmlist 127.0.0.1
```

Use the same host as `REALM_ADDRESS` in `.env`. Then log in with the account you created.

### CPU compatibility and local builds

If an older published image exits with code 132 (`SIGILL`), rebuild it locally with the same portable target and select it with `TURTLE_IMAGE`:

```bash
docker build \
  --build-arg BUILD_PLAYERBOTS=ON \
  --build-arg CPU_TARGET=x86-64-v2 \
  -t tortoise-wow:playerbots-local .
TURTLE_IMAGE=tortoise-wow:playerbots-local docker compose up -d
```

The `TURTLE_IMAGE` override is optional; without it, Compose uses the published image selected by `TAG`.

## Useful settings

| Setting | Default | Meaning |
|---|---|---|
| `REALM_ADDRESS` | `127.0.0.1` | Host the client uses to reach the world server |
| `REALM_NAME` | `TurtleWoW` | Name of the realm in the client list |
| `DATA_PATH` | `./data` | Folder with `dbc`, `maps`, `vmaps`, `mmaps` |
| `TAG` | `playerbots` | Image variant (`playerbots` or `no-bots`) |
| `TURTLE_IMAGE` | published image from `TAG` | Optional full image reference, useful for a local build |
| `AI_PLAYERBOT_ENABLED` | `1` | Turn bots on or off (`playerbots` image only) |
| `AI_MIN_RANDOM_BOTS` / `AI_MAX_RANDOM_BOTS` | `10` / `10` | How many random bots to keep online |

Keep bot counts low for the first start. Raise them later in `.env`, then run:

```bash
docker compose up -d mangosd
```

## Common commands

View logs:

```bash
docker compose logs -f realmd
docker compose logs -f mangosd
```

Stop the stack:

```bash
docker compose down
```

Start again (keeps your database):

```bash
docker compose up -d
```

Reset the database (deletes characters and accounts):

```bash
docker compose down
docker volume ls
docker volume rm tortoise-docker_db-data tortoise-docker_init-marker
docker compose up -d
```

Volume names can include your Compose project name. Use `docker volume ls` to confirm the names.

## Troubleshooting

| Problem | What to do |
|---|---|
| Login fails / unknown account | Wait for `World server is up and running`, then create the account again |
| Account create does nothing | mangosd is still starting; wait and retry |
| Realm list is empty or offline | Check that `realmd` and `mangosd` are up: `docker compose ps` |
| Client hangs after you pick the realm | Set `REALM_ADDRESS` to an IP the client can reach; world port is `8090` |
| Empty world / no NPCs | First database import failed; check `docker compose logs db-init` |
| No bots | Use `TAG=playerbots` and `AI_PLAYERBOT_ENABLED=1` |
| Client crash: interface corrupt | Use the published image from this project; do not strip Turtle addons |

## Credits

- Setup walkthrough: [YouTube video](https://www.youtube.com/watch?v=CNgkHs3btNE)
- Server source: [Shyalya/tortoise-wow](https://github.com/Shyalya/tortoise-wow)
- Install notes: [INSTALL-LINUX.md](https://github.com/Shyalya/tortoise-wow/blob/playerbots-integration-gh/INSTALL-LINUX.md)

Server code stays under the upstream project license. This repository only provides the Docker packaging.
