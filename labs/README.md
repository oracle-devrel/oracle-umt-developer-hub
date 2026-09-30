# Labs

Self-contained, runnable labs that validate converged-model claims against a live **Oracle AI Database 26ai**. Each lab ships a Docker environment, a validator, and its own README, and runs itself nightly in CI so the proofs stay honest.

| Name | Description | Link |
| --- | --- | --- |
| converged-database-lab | Runnable proofs for the converged-database article series — JSON Relational Duality, single-table vs. converged modeling, graph, vector, spatial, and full-text claims, each executing against a free Oracle AI Database 26ai container. | [./converged-database-lab](./converged-database-lab) |
| oracle-database-kafka-apis | Java integration tests demonstrating Oracle AI Database Transactional Event Queues through the Kafka APIs, backed by Testcontainers. | [./oracle-database-kafka-apis](./oracle-database-kafka-apis) |
| converged-modeling-patterns | Six document-modeling patterns as runnable side-by-sides — the document-model starting point and the converged alternative that keeps the read win without the write amplification — validated across SQL and the Oracle API for MongoDB with cross-API parity assertions, on a free Oracle AI Database 26ai container, plus a browser-based hands-on console (run and edit every query, measure document-model vs converged write cost live). | [./converged-modeling-patterns](./converged-modeling-patterns) |

*More labs coming as the content series expands.*
