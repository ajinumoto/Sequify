---
name: sequify
description: Generate sequence diagrams compatible with js-sequence-diagrams (bramp.github.io/js-sequence-diagrams) supporting 4 diagram modes (layman, operational, network, technical), format modifiers (detailed vs compact), automatic PNG/vector PDF compilation, and dedicated participant separation. Triggers on /sequify, /sequence, or /diagram.
---

# Sequify: Sequence Diagram Generator

Generate valid `js-sequence-diagrams` grammar, compile vector PDF and PNG artifacts, and provide mode-tailored architectural documentation.

---

## 1. Core Policies

- **Code Grounding & Adaptation**: Ground all participants, methods, endpoints, parameters, and flows strictly in the repository source code. Dynamically adapt naming, layers, and granularity to the target project's tech stack (Swift, Kotlin, Go, TypeScript, Python, etc.) and architectural patterns (MVC, MVVM, Clean Architecture, Hexagonal, Microservices, Event-Driven). Annotate unverified external systems with `Note over Service: External (unverified)`.
- **Language**: **English by default**. Translate only when explicitly requested by the user.
- **Redaction**: Replace credentials, tokens, and secrets with generic placeholders (e.g., `Bearer <TOKEN>`, `X-Key: <REDACTED>`).
- **Offline Safety**: 100% local macOS WebKit rendering with subresource integrity (SRI) verification.

---

## 2. Diagram Generation Modes

If no mode is specified, follow the user's prompt dynamically. When explicit, adopt the target persona:

| Mode | Aliases | Target Audience & Style | Supporting Table |
| :--- | :--- | :--- | :--- |
| **`default`** | *(None)* | Prompt-driven; matches user's explicit request. | Dynamic / Prompt-driven |
| **`layman`** | `non-technical`, `simple`, `basic`, `overview` | Non-technical stakeholders. Plain human terms (`"User"`, `"Mobile App"`). **No code, SQL, HTTP methods, or status codes.** | **User Journey**: Step \| User Action \| Screen Display \| Behind the Scenes |
| **`operational`** | `ops`, `business`, `product`, `process` | PMs & Operations. Focus on business modules, state transitions (`PENDING` $\rightarrow$ `ACTIVE`), feature flags, validation gates, and SLA limits. | **Business Operational Matrix**: Step \| Domain \| State Change \| Business Rule \| Fallback |
| **`network`** | `infra`, `infrastructure`, `devops`, `networking` | Network / DevOps. **Frontend codebase**: Client-side traffic only (`URLSession`, headers, caching, retries). **Backend codebase**: Gateway, VPC, service mesh, proxies. | **Network Spec Table**: Step \| Caller \| Target Endpoint \| Headers & Payload \| HTTP Status \| Retry/Cache Behavior |
| **`technical`** | `tech`, `code`, `engineering`, `architecture` | Developers & Architects. Dedicated microservices, controllers, DB queries, and caches. Supports `--scope` (`frontend`, `backend`, `security`, `fullstack`). | **API & Data Architecture Table**: Step \| Component/Caller \| Target API \| Method & Path \| Payload/Params \| Response Model \| DB/Cache Ops |

---

## 3. Format Modifiers: Standard vs Compact

Control structural density and noise level via flags (`--format compact`, `--compact`, `-c`, `condensed`, `concise`):

| Format | Scope & Behavior | Best For |
| :--- | :--- | :--- |
| **`standard`** (Default) | **Exhaustive Multi-Tier Tracing**: Captures every local layer hop (`UI` $\rightarrow$ `ViewModel` $\rightarrow$ `NetworkService` $\rightarrow$ `Engine`), state flag mutation, getter/setter bubbling, and detailed header notes. | Deep code audits, step-by-step debugging, and intra-module tracing. |
| **`compact`** | **Milestone & Substance-Driven**: Strips away repetitive glue code, trivial pass-throughs, and boilerplate bubbling. **Preserves core domain/technical actors, critical decisions, and milestone states.** | Architecture overviews, technical RFCs, and cross-team reviews. |

### Mode-Aware Rules for Compact Format (`--format compact`):
1. **Noise & Boilerplate Elimination**: Remove pure pass-through wrappers, trivial getter/setter cascades, and verbose intermediate delegate bubbling.
2. **Mode-Adapted Participant Abstraction**:
   - **In Technical Mode**: **Do NOT collapse everything into a single API box.** Keep the core domain classes, controllers, engines, managers, algorithms, databases, and caches (e.g., `CustomHTTPProtocol`, `NetworkInjectionManager`, `Datasource`). Focus on critical method calls, decision branches (`shouldInjectFailure()`), and state changes.
   - **In Network Mode**: Focus on endpoint transport boundaries, omitting intra-app view lifecycle hops.
   - **In Operational Mode**: Focus on domain boundary state changes (`PENDING` $\rightarrow$ `ACTIVE`).
   - **In Layman Mode**: Focus on primary user touchpoints and visible outcomes.
3. **Preserve Dedicated Target Separation**: Keep distinct microservices, third-party systems, and data stores clearly separated.
4. **Numbered Milestone Notes**: Group interactions into numbered logical phases (e.g., `Note over Interceptor,Engine: 1. Rule Evaluation & Delay Injection`).
5. **Succinct Labels**: Clean method calls, signatures, and concise model summaries instead of verbose raw payload dumps.
6. **Cross-Mode Compatible**: Seamlessly combines with any active mode (`--mode technical --format compact`, `--mode network --compact`, etc.).

---

## 4. Syntax & Grammar Rules (`js-sequence-diagrams`)

Strictly adhere to Andrew Brampton's grammar (`bramp.github.io/js-sequence-diagrams`):
- **Title**: `Title: <Title Text>`
- **Participants**: `participant <ActorName>` or `participant "<Actor Name>"` *(Unsupported: `as`, `activate/deactivate`, `alt/else`, `loop`)*.
- **Signals**: `->` (solid arrow), `-->` (dotted arrow), `->>` (open solid), `-->>` (open dotted), `-` (solid line), `--` (dotted line).
- **Notes**: `Note left of Actor: Text`, `Note right of Actor: Text`, `Note over Actor: Text`, `Note over Actor1,Actor2: Text` *(Use `\n` for multiline)*.
- **Comments**: `# Comment`
- **Sizing / Splitting**: If flow exceeds $>5-6$ participants or multiple distinct channels, split into modular method-specific sub-diagrams.

---

## 5. Visual Themes & Compilation Workflow

- **Theme**: Default `--theme simple` (clean vector lines). Use `--theme hand` only when user explicitly requests sketch/hand-drawn style.
- **Artifacts Generated**: Always generate exactly 3 core files:
  1. `<name>.seq` (Source grammar)
  2. `<name>.png` (High-DPI raster preview)
  3. `<name>.pdf` (Vector PDF document)

### Compilation Command:
```bash
swift /path/to/sequify/scripts/render_diagram.swift \
  -i "<appDataDir>/brain/<conversation-id>/<name>.seq" \
  -d "<appDataDir>/brain/<conversation-id>" \
  -p "<name>" \
  --theme simple \
  --format "pdf,png" \
  --title "<Title Text>"
```
*(Or `/path/to/sequify/scripts/sequify-cli <args>` if pre-compiled)*.

---

## 6. Output Presentation

In direct chat response:
1. **Indicator**: Active mode & format (e.g. `*Mode: Technical | Format: Compact*`).
2. **Visual Diagram**: Render native sequence code block (e.g. Mermaid `sequenceDiagram`) or embed PNG preview `![Sequence Diagram](file:///path/to/<name>.png)`.
3. **Specification Table**: Include mode-specific structured table.
4. **Walkthrough**: Concise explanation of the flow for the target audience.
5. **Artifact Links**: Clickable links to:
   - 📄 [Vector PDF](file:///path/to/<name>.pdf)
   - 🖼️ [Image Preview (PNG)](file:///path/to/<name>.png)
   - 📝 [Sequence Code (.seq)](file:///path/to/<name>.seq)
   - 📑 [Markdown Document](file:///path/to/<name>.md)
