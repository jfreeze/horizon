# Horizon


`Horizon` provides tools for host configuration (build, postgresql db, web) and tools to deploy any Elixir app that uses `mix release`. 

```mermaid
graph LR
    A[Horizon.init] --> B[STAGE]
    B --> C[BUILD]
    C --> D[DEPLOY]
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `horizon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:horizon, "~> 0.1.0"}
  ]
end
```

## Host Configuration

### Sample Postgres Host Configuration

`#postgres.conf`
```
pkg:postgresql16-server
pkg:postgresql16-contrib
postgres.init

postgres.db:c_mixed_utf8:mydb
```

### Sample Build Host Configuration

`#build.conf`
```
pkg:ca_root_nss
pkg:gcc
pkg:rsync
pkg:gmake
pkg:erlang-runtime27

path:/usr/local/lib/erlang27/bin
elixir:1.17.3
```

### Sample Web Host Configuration

`#web.conf`
```
pkg:vips
```


With hosts configured, you can now build and deploy an Elixir app.

- Staging copies the app source to the build machine.
- Building creates a tarball that is ready to run on a deploy host.
- Deploy copies the tarball to the build machine and starts the service. (JEDI can allow hot deploys to a running service.)


## Deploying an Elixir App

```shell
mix horizon.init
./bin/stage-my_app.sh
./bin/build-my_app.sh
./bin/deploy-my_app.sh [deploys to build host by default]
./bin/deploy-my_app.sh -h target_host -u target_user my_app-0.1.2.tar.gz
```

### Deploy Stages

#### Stage
copies app source to the build host.

#### Build
builds the deploy artifacts. If you have added `Horizon.Step.setup` 
to your release steps, then the `rc_d` script will be generated and put in `rel/overlay`.

#### Deploy
copies the tarball to the target host and starts the service.



ssj 176 "(cd /usr/local/opt/phx_only/build; . ~/.shrc; doas ./bin1/build-phx_only.sh)"

ssj 176 "(cd /usr/local/opt/phx_only/build; PATH=/usr/local/erlang27/bin:$PATH doas ./bin1/build-phx_only.sh)"


[![Elixir](d)](https://elixir-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Welcome to **Horizon**, an Elixir project that [briefly describe what Horizon does].





## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
- [Usage](#usage)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Introduction

Horizon is a [detailed description of your project]. It aims to [state goals or solve specific problems].

## Features

- **Scalable Architecture**: Built with scalability in mind.
- **High Performance**: Optimized for speed and efficiency.
- **Ease of Use**: Simple APIs and comprehensive documentation.

## Installation

### Prerequisites

- Elixir ~> 1.12
- Erlang/OTP ~> 24
- [Additional prerequisites]

### Setup

1. **Clone the Repository**

## BSD Build File

You can configure

### Configuring a Web Host

### Configuring a Postgres Host


---


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/horizon>.



