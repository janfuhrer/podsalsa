# Additional information

Supplementary material that is **not part of the release pipeline**. These documents explore
tooling around the artifacts PodSalsa produces — mostly what you can do with the SBOMs once
you have verified them.

They are kept because the walkthroughs are still instructive, but they are exploratory notes
rather than maintained parts of the project. Versions, screenshots and third-party UIs may
have moved on since they were written.

For the parts that *are* maintained — building, signing, provenance and verification — start
at the [documentation index](../README.md).

## Contents

| Topic | Description |
| :--- | :--- |
| [Component analysis](./component-analysis/) | What component analysis is, and which tools were evaluated |
| [Dependency-Track](./component-analysis/dependency-track/) | OWASP's continuous component analysis platform |
| [GUAC](./component-analysis/guac/) | OpenSSF's "Graph for Understanding Artifact Composition" |
| [Local Kubernetes deployment](./component-analysis/dependency-track/deployment/) | Running Dependency-Track and sbom-operator on a kind cluster |
