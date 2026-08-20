---
name: sequify
description: Generate sequence diagrams compatible with js-sequence-diagrams (bramp.github.io/js-sequence-diagrams) supporting 4 diagram modes (layman, operational, network, technical), format modifiers (detailed vs compact), automatic PNG/vector PDF compilation, and dedicated participant separation. Triggers on /sequify, /sequence, or /diagram.
---

# Sequify: Sequence Diagram Generator

Generate valid `js-sequence-diagrams` grammar, compile vector PDF and PNG artifacts, and provide mode-tailored architectural documentation.

---

## 1. Core Policies

- **Code Grounding**: All participants, methods, endpoints, parameters, and flows **MUST** be verified from repository source code. Never hallucinate or assume non-existent classes or routes. Annotate unverified external systems with `Note over Service: External (unverified)`.
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

Control structural density via flags (`--format compact`, `--compact`, `-c`, `condensed`, `concise`):

| Format | Scope & Behavior | Best For |
| :--- | :--- | :--- |
| **`standard`** (Default) | Full multi-layer tracing (`UI` $\rightarrow$ `ViewModel` $\rightarrow$ `NetworkService` $\rightarrow$ `API`). Captures local calls, state mutations, and header notes. | Deep code audits & internal debugging. |
| **`compact`** | **Concise & to the point**: Collapses internal client layers into 1 caller (`"iOS App (Client)"`), direct signals to dedicated target APIs, numbered milestone notes. | Architecture overviews, PR reviews & RFCs. |

### Rules for Compact Format (`--format compact`):
1. **Collapse Client Tiers**: Group internal layers (`UI`, `ViewModel`, `NetworkService`, `Repository`) into a single caller participant (e.g. `participant "iOS App (Client)"`).
2. **Direct Target Signals**: Draw signals directly between caller and target APIs/services. Eliminate local function hops and response bubbling.
3. **Preserve Dedicated Target Separation**: Keep distinct APIs and services isolated (e.g. `participant "Remote Backend API"`, `participant "HTTP Datasource"`).
4. **Numbered Milestone Notes**: Replace verbose header/auth notes with numbered milestones (e.g. `Note over "iOS App (Client)","DebugSwift Engine": 1. Intercept & Apply Rewrite Rule`).
5. **Clean Labels**: Concise method + endpoint (`URLRequest: /users/profile`, `POST /auth/login`) and status + model summary (`200 OK (User Profile)`).
6. **Cross-Mode Compatible**: Combines with any mode (e.g., `--mode network --format compact`).

#### Standard vs Compact Comparison:
```sequence
# Standard (Detailed)
Title: DebugSwift Network Injection (Standard)
participant "iOS App (URLSession)"
participant "CustomHTTPProtocol"
participant "NetworkInjectionManager"
participant "URLProtocolClient"

"iOS App (URLSession)"->"CustomHTTPProtocol": startLoading() [URLRequest: /users/profile]
"CustomHTTPProtocol"->"NetworkInjectionManager": applyDelayIfNeeded(for: request)
"CustomHTTPProtocol"->"NetworkInjectionManager": matchingRewriteRule(for: request)
"NetworkInjectionManager"-->"CustomHTTPProtocol": RewriteRule(url: "*/users/*", shortCircuit: true)
"CustomHTTPProtocol"->"URLProtocolClient": didReceive(HTTPURLResponse status: 200 OK)
"URLProtocolClient"-->"iOS App (URLSession)": Completion Handler (Mock Profile)
```
```sequence
# Compact (--format compact)
Title: DebugSwift Network Injection (Compact)
participant "iOS App (Client)"
participant "DebugSwift Engine"
participant "HTTP Datasource"

Note over "iOS App (Client)","DebugSwift Engine": 1. Intercept & Apply Rewrite Rule
"iOS App (Client)"->"DebugSwift Engine": URLRequest: /users/profile
"DebugSwift Engine"-->"iOS App (Client)": 200 OK (Rewritten Mock Profile)
Note over "DebugSwift Engine","HTTP Datasource": 2. Record Metrics
"DebugSwift Engine"->"HTTP Datasource": Log Mock Transaction (1.50s)
```

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
