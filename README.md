# Packer CI 📦🚀

**A lean, multi-arch container image that ships [HashiCorp Packer](https://www.packer.io/) pre-loaded with the plugins you actually need — ready to drop straight into your CI/CD pipelines.**

Building machine images (VM templates, cloud images, containers) in CI shouldn't mean hand-rolling a Docker image every time you need a new Packer plugin. **Packer CI** does that work for you: it takes a minimal, security-conscious base image, installs Packer at a pinned version, and bakes in a curated set of plugins — all built and published automatically for both `amd64` and `arm64`.

---

## ✨ What's inside

- **HashiCorp Packer**, pinned to an exact version (see [`VERSION`](VERSION)) — no surprises, no drift.
- **Pre-installed plugins**, declared declaratively in [`PLUGINS`](PLUGINS) and downloaded straight from their source repositories at build time.
- **A minimal footprint**, built on [Photon OS](https://vmware.github.io/photon/), VMware's security-hardened, container-optimized Linux distribution.
- **Multi-architecture support** — every image is built for both `linux/amd64` and `linux/arm64` in a single pipeline run using Docker Buildx.
- **Fully automated builds** via GitLab CI, including versioned tags and an optional `:latest` tag.

## 🔌 Included plugins

| Plugin | Source |
|---|---|
| [packer-plugin-vsphere](https://github.com/vmware/packer-plugin-vsphere) | VMware |
| [packer-plugin-salt](https://github.com/mpoore/packer-plugin-salt) | mpoore |

Plugins are versioned independently of Packer itself — see [`PLUGINS`](PLUGINS) for exact pinned versions. Each plugin's version is also recorded as an OCI label on the built image, so you can always inspect exactly what's inside a given tag.

## 🚀 Usage

Pull the image and run Packer just as you would locally:

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace <your-registry>/packer-ci:<version> \
  packer init .
```

Or use it as the base for a CI job:

```yaml
build-image:
  image: <your-registry>/packer-ci:latest
  script:
    - packer init .
    - packer build .
```

## 🛠️ How it's built

The [`Dockerfile`](Dockerfile) uses a multi-stage build:

1. A `base` stage installs common tooling (`unzip`, `git`, `wget`, `jq`, etc.) on top of Photon OS.
2. A `packer` stage downloads and unpacks the pinned Packer release, then loops over [`PLUGINS`](PLUGINS) to fetch and install each plugin binary for the target OS/architecture.
3. A final stage copies just the resulting binaries into a clean image, keeping the final footprint small.

The [`.gitlab-ci.yml`](.gitlab-ci.yml) pipeline drives the whole process: it reads the desired version from [`VERSION`](VERSION), appends plugin version labels to the Dockerfile, and builds/pushes multi-arch images with Buildx — tagging `:latest` automatically when flagged in `VERSION`.

### Bumping versions

- **Packer version:** edit `version` in [`VERSION`](VERSION).
- **`latest` tag:** toggle `latest` (`"true"`/`"false"`) in [`VERSION`](VERSION).
- **Plugins:** add, remove, or update entries under `plugins` in [`PLUGINS`](PLUGINS) — each needs a `name`, `version`, and `source` (GitHub repository URL).

## 📄 License

This repository is licensed under the **[GNU General Public License v3.0](LICENSE)**.

In short: you're free to use, study, modify, and redistribute this code — including commercially — as long as any distributed modifications or derivative works are also released under the GPLv3 and keep their source available. It's a strong "copyleft" license, designed to guarantee that this project and anything built on top of it stay free and open for everyone downstream.

> **Note:** this license covers the files in *this* repository (the Dockerfile, CI pipeline, and configuration). The Packer binary and plugins downloaded and bundled *into* the resulting container image are separate software with their own licenses — including Apache-2.0, BUSL-1.1, and MPL-2.0 — as declared in the image's `org.opencontainers.image.licenses` label.

## 👤 Author

Maintained by [Michael Poore](https://mpoore.io).