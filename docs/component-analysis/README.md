# Component Analysis

Component analysis is the process of identifying potential areas of risk arising from the use of third party and open source software and hardware components. Component Analysis is one function within an overall [Cyber Supply Chain Risk Management (C-SCRM)](https://csrc.nist.gov/projects/cyber-supply-chain-risk-management) framework. A software-only subset of Component Analysis with a limited scope is commonly referred to as Software Composition Analysis (SCA).

When organizations use third party and open source software components, they inherit the risk associated with those components. This risk can include licensing issues, security vulnerabilities and other potential problems. Component analysis is the process of identifying and mitigating these risks.

To gather information about the components used in a piece of software, the software's Software Bill of Materials (SBOM) can be used. An SBOM is similar to the list of ingredients in a recipe and provides a detailed list of all the components used in a piece of software. There are several SBOM standards, such as OWASP's [CycloneDX](https://cyclonedx.org/) and the Linux Foundation's [SPDX](https://spdx.dev/).

To track all components and scan them for vulnerabilities, organisations can use tools such as [Dependency-Track](https://docs.dependencytrack.org/) or [GUAC](https://guac.sh/).

## Tools

The following tools were analyzed. Click on the links to get more information about the usage and installation of the tools.

- [Dependency-Track](./dependency-track/README.md) by OWASP
- [GUAC](./guac/README.md), an OpenSSF incubating project

## Sources

- [OWASP Component Analysis](https://owasp.org/www-community/Component_Analysis)
