# Iced Calculator

A calculator application for the [COSMIC][cosmic] desktop environment, built with [libcosmic][libcosmic] and Rust.

This is not associated with Pop OS, Cosmic, or System 76. It implements a Cosmic UI and the ELM architecture.

## Features

- **Basic mode** — standard arithmetic with a button-grid UI: addition, subtraction, multiplication, division, parentheses, sign toggle, and percentage
- **Factorial** — integer and floating-point factorial via the `!` operator, with gamma function support for non-integers
- **Expression history** — scrollable list of past calculations with copy-to-input support
- **Keyboard input** — type expressions directly or use the on-screen buttons
- **Advanced and Developer modes** — placeholder pages for future functionality

### Architecture

The project is split into two crates:

| Crate              | Purpose                                                                                   |
| ------------------ | ----------------------------------------------------------------------------------------- |
| `iced-calc` (root) | COSMIC/Iced GUI application                                                               |
| `calclib`          | Standalone expression engine — lexer, parser, AST, and evaluator with no GUI dependencies |

## Installation

Prebuilt packages are available for **amd64** and **arm64** on Ubuntu 24.04+, Linux Mint 22+, Pop!_OS 24.04+, and Debian 13+. Older releases (Ubuntu 22.04, Mint 21, Debian 12) are not supported.

### apt repository (recommended)

Adding the repository gives you updates through `apt upgrade`:

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://jepomeroy.github.io/iced-calc/iced-calc.gpg | sudo tee /etc/apt/keyrings/iced-calc.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/iced-calc.gpg] https://jepomeroy.github.io/iced-calc stable main" | sudo tee /etc/apt/sources.list.d/iced-calc.list
sudo apt update
sudo apt install iced-calc
```

To remove it again:

```sh
sudo apt remove iced-calc
sudo rm /etc/apt/sources.list.d/iced-calc.list /etc/apt/keyrings/iced-calc.gpg
```

### Single .deb download

Download `iced-calc_<version>-1_<arch>.deb` from the [releases page](https://github.com/jepomeroy/iced-calc/releases), then:

```sh
sudo apt install ./iced-calc_*.deb
```

This installs the runtime dependencies automatically, but won't update the app later.

## Building from source

### 1. Install build dependencies

On Ubuntu 24.04+, Linux Mint 22+, Pop!_OS, or Debian 13+:

```sh
sudo apt install build-essential git curl just pkg-config \
  libxkbcommon-dev libwayland-dev libexpat1-dev libfontconfig-dev libfreetype-dev
```

Then install Rust with [rustup][rustup]. The distro's `cargo` package is too old for this project, which uses the Rust 2024 edition and needs Rust 1.85 or newer.

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 2. Build and install

```sh
git clone https://github.com/jepomeroy/iced-calc.git
cd iced-calc
just build-release
sudo just install
```

This installs the binary, desktop entry, AppStream metadata, and icon under `/usr`. Change the location with `rootdir` and `prefix`:

```sh
just prefix=$HOME/.local install          # per-user install, no sudo
just rootdir=/tmp/staging prefix=/usr install
```

To uninstall, run `sudo just uninstall`, passing the same `prefix` you installed with.

### 3. Or build a .deb locally

```sh
cargo install cargo-deb
just deb
sudo apt install ./target/debian/iced-calc_*.deb
```

### just recipes

A [justfile](./justfile) is provided for the [just][just] command runner:

| Command            | Description                                            |
| ------------------ | ------------------------------------------------------ |
| `just`             | Build the release binary (default recipe)              |
| `just run`         | Build and run the application                          |
| `just build-debug` | Build with the debug profile                           |
| `just test`        | Run all tests across the workspace                     |
| `just test-watch`  | Continuously run tests with [bacon][bacon]             |
| `just check`       | Run clippy with pedantic warnings                      |
| `just check-json`  | Clippy with JSON output for IDE/LSP integration        |
| `just deb`         | Build a `.deb` into `target/debian/` (needs cargo-deb) |
| `just install`     | Install to `prefix` (default `/usr`)                   |
| `just uninstall`   | Remove installed files                                 |
| `just clean`       | Run `cargo clean`                                      |

## Packaging

For distribution packaging, vendor dependencies and build offline:

```sh
just vendor
just build-vendored
just rootdir=debian/iced-calc prefix=/usr install
```

It is recommended to create the vendored tarball on the host system before entering a sandboxed build environment.

## Translators

[Fluent][fluent] is used for localization. Translation files live in the [i18n directory](./i18n). To add a new language:

1. Copy the [English (en) localization](./i18n/en) directory
2. Rename it to the target [ISO 639-1 language code][iso-codes]
3. Translate each [message identifier][fluent-guide] (messages without a translation can be omitted)

## Development

Install [rustup][rustup] and configure your editor with [rust-analyzer][rust-analyzer]. Optional speed-ups:

- Disable LTO in the release profile
- Install the [mold][mold] linker (only benefits builds with LTO disabled)
- Use [sccache][sccache] for compilation caching

Run the `calclib` tests on their own (they don't need the GUI build dependencies):

```sh
cargo test -p calclib
```

### Before opening a pull request

CI runs these checks on every PR to `main`, and all of them must pass:

```sh
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace
```

**Bump the version.** If the PR changes anything that ends up in the package (source, `Cargo.toml`/`Cargo.lock`, `i18n/`, `resources/`), increase `version` in the root `Cargo.toml`. CI fails if the version isn't higher than `main`'s or was already released. PRs that only touch docs, CI, or tooling files don't need a bump; the full list is in [`scripts/needs-release.sh`](./scripts/needs-release.sh).

### Releases

Merging to `main` builds `.deb` packages for amd64 and arm64, publishes them as a GitHub release tagged `v<version>`, and updates the apt repository. Nothing needs to be tagged by hand.

## Code of Conduct

This project follows the [Contributor Covenant](./CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## License

[MIT](./LICENSE)

[bacon]: https://github.com/Canop/bacon
[cosmic]: https://system76.com/cosmic
[fluent]: https://projectfluent.org/
[fluent-guide]: https://projectfluent.org/fluent/guide/hello.html
[iso-codes]: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
[just]: https://github.com/casey/just
[libcosmic]: https://github.com/pop-os/libcosmic
[mold]: https://github.com/rui314/mold
[rust-analyzer]: https://rust-analyzer.github.io/
[rustup]: https://rustup.rs/
[sccache]: https://github.com/mozilla/sccache
