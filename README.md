# Oracle UMT Developer Hub

[![License: UPL](https://img.shields.io/badge/license-UPL-green)](https://oss.oracle.com/licenses/upl/)

Technical resources for developers learning **Unified Model Theory (UMT)** and converged data modeling on **Oracle AI Database 26ai** — *model the domain once, project the access for every consumer.*

This hub collects hands-on, **runnable** labs and companion material for the UMT / converged-database content series. Nothing here is slideware: every lab boots a real Oracle AI Database 26ai container and proves its claims by executing them — document, relational, graph, vector, spatial, and full-text in **one engine, one transaction, one optimizer.**

> **One truth. Many shapes. Every claim runs.**

## What You'll Find

This repository is organized so that each runnable asset lives in its own folder under a category. More labs and companion material will be added as the series grows.

### 🧪 Labs (`/labs`)

Self-contained, runnable labs that validate converged-model claims against a live Oracle AI Database 26ai. Each lab includes a Docker environment, a validator, and its own README and quickstart, and runs itself nightly in CI so the proofs stay honest.

| Name | Description | Link |
| --- | --- | --- |
| converged-database-lab | Runnable proofs for the converged-database article series — JSON Relational Duality, single-table vs. converged modeling, graph, vector, spatial, and full-text claims, each executing against a free Oracle AI Database 26ai container. | [![View Lab](https://img.shields.io/badge/View%20Lab-blue?style=flat-square)](./labs/converged-database-lab) |

*More labs coming as the content series expands.*

## Getting Started

Each lab is self-contained. To run the converged-database lab:

```bash
cd labs/converged-database-lab
docker compose up -d --build oracle   # ~2 GB image; first boot seeds the domain (~2 min)
pip install -r validator/requirements.txt
python validator/run.py               # runs every module, prints ASSERT results
```

See the lab's own [README](./labs/converged-database-lab) for details, troubleshooting, and the module map.

## About Unified Model Theory

Relational and document are not competing paradigms — they are **orthogonal projections of the same truth.** UMT models the domain once as a normalized **canonical form**, then projects whatever **shape** each consumer needs — a document, a graph, a vector, a relational result — from that single source, with no copies to drift out of sync. On a converged engine, the access pattern still drives the model; you just stop walking through one-way doors to serve it.

## Contributing

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md).

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process.

## License

Copyright (c) 2026 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at <https://oss.oracle.com/licenses/upl/>.

## Disclaimer

ORACLE AND ITS AFFILIATES DO NOT PROVIDE ANY WARRANTY WHATSOEVER, EXPRESS OR IMPLIED, FOR ANY SOFTWARE, MATERIAL OR CONTENT OF ANY KIND CONTAINED OR PRODUCED WITHIN THIS REPOSITORY, AND IN PARTICULAR SPECIFICALLY DISCLAIM ANY AND ALL IMPLIED WARRANTIES OF TITLE, MERCHANTABILITY, AND FITNESS FOR A PARTICULAR PURPOSE. FURTHERMORE, ORACLE AND ITS AFFILIATES DO NOT REPRESENT THAT ANY CUSTOMARY SECURITY REVIEW HAS BEEN PERFORMED WITH RESPECT TO ANY SOFTWARE, MATERIAL OR CONTENT CONTAINED OR PRODUCED WITHIN THIS REPOSITORY. IN ADDITION, AND WITHOUT LIMITING THE FOREGOING, THIRD PARTIES MAY HAVE POSTED SOFTWARE, MATERIAL OR CONTENT TO THIS REPOSITORY WITHOUT ANY WARRANTY OF ANY KIND, INCLUDING THAT THE CONTENT IS FREE OF DEFECTS, MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE OR NON-INFRINGING. ANY OPEN SOURCE SOFTWARE IS PROVIDED BY THE APPLICABLE LICENSOR "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
