# InstaSwap

What is InstaSwap?

InstaSwap is a decentralized token swap protocol for ERC-1155 tokens on Starknet. In other words, InstaSwap is Uniswap for ERC-1155 tokens.Users can trade up to `n` amount of ERC1155 tokens in one transaction with a ERC20 token!

*Greatly inspired by Uniswap and Niftyswap,thanks for the work done by the Uniswap team and Niftyswap team*


# Contribute

Contribution are welcome! Please check the good first issues for a list of issues that are good for new contributors.

# Development

## Installing dependencies

### Step 1: Install Cairo 1.0 (guide by [Abdel](https://github.com/abdelhamidbakhta))

If you are on an x86 Linux system and able to use the release binary,
you can download Cairo here https://github.com/starkware-libs/cairo/releases.

For everyone, else, we recommend compiling Cairo from source like so:

```bash
# Install stable Rust
$ rustup override set stable && rustup update

# Clone the Cairo compiler in $HOME/Bin
$ cd ~/Bin && git clone git@github.com:starkware-libs/cairo.git && cd cairo

# Generate release binaries
$ cargo build --all --release
```

**NOTE: Keeping Cairo up to date**

Now that your Cairo compiler is in a cloned repository, all you will need to do
is pull the latest changes and rebuild as follows:

```bash
$ cd ~/Bin/cairo && git fetch && git pull && cargo build --all --release
```

### Step 2: Add Cairo 1.0 executables to your path

```bash
export PATH="$HOME/Bin/cairo/target/release:$PATH"
```

**NOTE: If installing from a Linux binary, adapt the destination path accordingly.**

This will make available several binaries. The one we use is called `cairo-test`.

### Step 3: Install the Cairo package manager Scarb

Follow the installation guide in [Scarb's Repository](https://github.com/software-mansion/scarb).

### Step 4: Setup Language Server

#### VS Code Extension

- Disable previous Cairo 0.x extension
- Install the Cairo 1 extension for proper syntax highlighting and code navigation.
Just follow the steps indicated [here](https://github.com/starkware-libs/cairo/blob/main/vscode-cairo/README.md).

#### Cairo Language Server

From [Step 1](#step-1-install-cairo-10-guide-by-abdel), the `cairo-language-server` binary should be built and executing this command will copy its path into your clipboard.

```bash
$ which cairo-language-server | pbcopy
```

Update the `languageServerPath` of the Cairo 1.0 extension by pasting the path.

### Build

Build the contracts.

```bash
$ make build
```

### Test

Run the tests in `src/test`:

```bash
$ make test
```

### Format

Format the Cairo source code (using Scarb):

```bash
$ make fmt
```

### Sierra (advanced)

View the compiled Sierra output of your Cairo code:

```bash
$ make sierra
```