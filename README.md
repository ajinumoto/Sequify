<div align="center">

# 📊 Sequify

**Offline Sequence Diagram & Vector PDF Generator for AI Coding Agents**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-black.svg?logo=apple)](https://apple.com)
[![Skills.sh Compatible](https://img.shields.io/badge/Skills.sh-Compatible-10b981.svg)](https://skills.sh)
[![Zero NPM Deps](https://img.shields.io/badge/Dependencies-Zero%20NPM-brightgreen.svg)](#-key-features)
[![Engine: WebKit Native](https://img.shields.io/badge/Engine-WebKit%20Native-orange.svg)](#-how-it-works)

<p align="center">
  Transform code flows into <b>interactive visual diagrams</b>, <b>structured API specification tables</b>, and <b>printable vector PDF artifacts</b> — generated 100% offline in under 2 seconds.
</p>

[Installation](#-installation) • [Diagram Modes](#-diagram-modes) • [Output Specs](#-output-specifications) • [Usage](#-usage-in-antigravity) • [Architecture](#-repository-architecture) • [License](#-license)

</div>

---

## 💡 Overview

When designing system architectures with AI coding assistants, standard text code blocks are difficult to share and review. 

**Sequify** bridges this gap: with a single action (`/sequify`, `/sequence`, or `/diagram`), the AI analyzes your codebase, isolates microservices into dedicated participant headers, and automatically compiles the flow into **visual previews**, **structured data contracts**, and **downloadable vector PDFs**.

```
┌─────────────────┐       ┌─────────────────┐       ┌───────────────────────────────┐
│   User Prompt   │ ───►  │ Mode Resolution │ ───►  │        Sequify Engine         │
│  "/sequify..."  │       │ & Grammar Gen   │       │  (Headless Native WebKit CLI) │
└─────────────────┘       └─────────────────┘       └──────────────┬────────────────┘
                                                                   │
                                      ┌────────────────────────────┴────────────────────────────┐
                                      ▼                                                         ▼
                       ┌─────────────────────────────┐                           ┌─────────────────────────────┐
                       │      Agent Chat Output      │                           │      Generated Artifacts    │
                       ├─────────────────────────────┤                           ├─────────────────────────────┤
                       │ • Native Visual Diagram     │                           │ • 📄 <flow>.pdf (Vector)   │
                       │ • Mode Specification Table  │                           │ • 🖼️ <flow>.png (High-DPI) │
                       │ • Concise Flow Walkthrough  │                           │ • 📝 <flow>.seq (Grammar)   │
                       │ • Direct Artifact Links     │                           │ • 📑 <flow>.md  (Document)  │
                       └─────────────────────────────┘                           └─────────────────────────────┘
```

---

## 🎯 Diagram Modes

Sequify provides **4 specialized diagram modes** alongside a prompt-driven default mode:

> [!IMPORTANT]
> **Priority 1: Prompt-Driven Default Behavior**
> By default (when no mode is specified), Sequify does **not** enforce any persona constraints. The generated diagram and documentation strictly follow your prompt's explicit requirements.

> [!NOTE]
> **Default Language**: All diagram titles, participant names, notes, tables, and explanations are generated in **English** by default. If you explicitly request another language (e.g. *"generate in Indonesian"*), Sequify translates the content while preserving all structure and grammar rules.

When a specific mode is requested, Sequify adjusts participant abstraction, terminology, signal depth, and supporting tables for the target persona, **dynamically adapted to your codebase type (Frontend/Mobile vs Backend/Infra)**:

| Mode | Trigger Flags & Aliases | Target Audience | Participant Abstraction | Supporting Table Output |
| :--- | :--- | :--- | :--- | :--- |
| **`default`** | *(None)* | General / Prompt-driven | As specified in user prompt | Prompt-driven |
| **`layman`** | `--mode layman`, `-m layman`, `non-technical`, `simple`, `basic` | End-users, non-technical stakeholders (Zero code & product knowledge) | Plain, human-friendly terms (`"User"`, `"Mobile App"`, `"Payment Service"`) | **User Journey Step Table** (Action, Screen Display, Behind the Scenes) |
| **`operational`** | `--mode operational`, `-m operational`, `ops`, `business`, `product` | PMs & Operations (Deep product knowledge, minimal code knowledge) | Business domains & state rules (`"UI State"`, `"Subscription Module"`, `"Feature Flags"`) | **Business Operational Matrix** (Domain, State Change, Business Rule, Fallback) |
| **`network`** | `--mode network`, `-m network`, `infra`, `devops`, `networking` | Network Engineers, DevOps, SecOps, & Developers | Context-adaptive: Client traffic (`"URLSession"`, `"HTTP Client"`) or Cloud Infra (`"Ingress"`, `"Gateway"`) | **Client Network Traffic Table** (Frontend) or **Network Boundary Table** (Backend) |
| **`technical`** | `--mode technical`, `-m technical`, `tech`, `code`, `engineering` | Software Engineers, Architects, Tech Leads (Deep code & product knowledge) | Dedicated API endpoints, controllers, DBs, caches (`"SubscriptionController"`, `"Redis"`) | **Structured API & Model Table** (HTTP Method, Path, Headers, Payload, DB Ops) |

---

## 🎯 Output Specifications

Sequify follows a clean, predictable two-tier output format:

### 1. In-Chat Agent Response
* **Visual Diagram**: Rendered directly in chat via native agent diagram syntax (e.g. Mermaid sequence block) or high-DPI image preview.
* **Mode-Specific Specifications Matrix**: Comprehensive table tailored to the active mode (User Journey / Business Matrix / Network Security Table / API Specifications Matrix).
* **Flow Explanation**: Clear architectural walkthrough highlighting key steps for the target persona.
* **Direct File Links**: Clickable links to open the generated PDF, image, and sequence files.

### 2. Export Artifacts & Files
Strictly generates only **3 core files** per diagram:

| File Extension | Format | Description |
| :--- | :--- | :--- |
| **`.pdf`** | Vector PDF Document | High-resolution, printable PDF document formatted for architectural reviews and PR attachments. |
| **`.png`** | High-DPI Raster Image | Crisp image preview embedded directly in IDE Markdown artifacts. |
| **`.seq`** | Plaintext Grammar | Raw [js-sequence-diagrams](https://bramp.github.io/js-sequence-diagrams/) source code for manual editing. |

---

## ✨ Key Features

- **⚡ 100% Offline & Self-Contained**: Bundles all JavaScript engines (`Snap.svg`, `Underscore`, `js-sequence-diagrams`) and fonts. No internet access or node modules required at runtime.
- **🚀 Native macOS WebKit Engine**: Swift-powered headless rendering compiles complex multi-actor flows to vector PDF and PNG in sub-seconds.
- **🎨 Two Visual Themes**:
  - `simple`: Modern, clean vector lines and crisp sans-serif typography.
  - `hand`: Expressive hand-drawn sketch style with embedded Architects Daughter font.
- **🔒 Dedicated API Separation**: Automatically isolates backend microservices into dedicated participant headers instead of generic backend blocks.
- **🔍 Code-Grounded & Zero Hallucination**: Strictly treats your codebase as the sole source of truth—never hallucinating non-existent classes, endpoints, or speculative flows.

---

## 🚀 Installation

### Option 1: Via `npx skills` (Recommended)

Install using the open agent ecosystem tool ([skills.sh](https://skills.sh)):

```bash
# Global installation (Available across all workspaces and agents)
npx skills add ajinumoto/Sequify -g

# Or install for the current workspace only
npx skills add ajinumoto/Sequify
```

---

### Option 2: 1-Line Terminal Installer

```bash
curl -fsSL https://raw.githubusercontent.com/ajinumoto/Sequify/main/install.sh | bash
```

---

### Option 3: Team Workspace Git Sharing

To share Sequify automatically with your team in a shared repository:

```bash
cd /path/to/your/project

# Install into workspace .agents directory
curl -fsSL https://raw.githubusercontent.com/ajinumoto/Sequify/main/install.sh | bash -s -- --workspace .

# Commit to Git
git add .agents/skills/sequify
git commit -m "feat: add Sequify sequence diagram skill"
git push
```

> **Note**: Any team member who clones the repository will automatically have the `/sequify`, `/sequence`, and `/diagram` actions available without extra configuration.

---

## 🛠️ Usage in Antigravity: Real-World Case Study Across Modes

Trigger Sequify by typing `/sequify`, `/sequence`, `/diagram`, or asking naturally in your prompt. Below are visual examples of a **real-world production case study**—inspecting the **Network Injection & Interception Engine** from [DebugSwift](https://github.com/DebugSwift/DebugSwift) (`CustomHTTPProtocol` $\leftrightarrow$ `NetworkInjectionManager`) executed across different modes and themes:

### 1. Technical Mode (`--mode technical`)
> Complete technical flow of iOS networking interception: `CustomHTTPProtocol.startLoading()`, `NetworkInjectionManager` delay injection, failure evaluation, wildcard rewrite rule matching, local short-circuit response dispatch, and metrics logging to `HTTP.Datasource`.

```text
/sequify --mode technical Inspect DebugSwift Network Injection and Interception flow
```

<p align="center">
  <img src="docs/assets/debugswift_network_technical.png" alt="Technical Mode DebugSwift Network Injection Sequence Diagram" width="100%">
</p>

<p align="center">
  📄 <a href="docs/assets/debugswift_network_technical.pdf"><b>Download Vector PDF</b></a> • 🖼️ <a href="docs/assets/debugswift_network_technical.png"><b>View High-DPI PNG</b></a> • 📝 <a href="docs/assets/debugswift_network_technical.seq"><b>View Sequence Source (.seq)</b></a>
</p>

---

### 2. Operational Mode (`--mode operational`)
> QA & Developer in-app debugging workflow: Enabling dynamic response rewrite rules via in-app UI, persisting rules to storage, intercepting live app network traffic, and surfacing floating mock badges and payload diffs.

```text
/sequify --mode operational DebugSwift Network simulation and response mocking
```

<p align="center">
  <img src="docs/assets/debugswift_network_operational.png" alt="Operational Mode DebugSwift Network Mocking Sequence Diagram" width="100%">
</p>

<p align="center">
  📄 <a href="docs/assets/debugswift_network_operational.pdf"><b>Download Vector PDF</b></a> • 🖼️ <a href="docs/assets/debugswift_network_operational.png"><b>View High-DPI PNG</b></a> • 📝 <a href="docs/assets/debugswift_network_operational.seq"><b>View Sequence Source (.seq)</b></a>
</p>

---

### 3. Network & Infrastructure Mode (`--mode network`)
> Protocol layer, kernel socket synthesis, and network failure boundaries: Layer 7 `URLProtocol` registration, failure injection rate simulation (`NSURLErrorTimedOut -1001`), socket synthesis abort, and edge gateway bypass.

```text
/sequify --mode network DebugSwift Layer 7 protocol interception and error injection
```

<p align="center">
  <img src="docs/assets/debugswift_network_network.png" alt="Network Mode DebugSwift Traffic Interception Sequence Diagram" width="100%">
</p>

<p align="center">
  📄 <a href="docs/assets/debugswift_network_network.pdf"><b>Download Vector PDF</b></a> • 🖼️ <a href="docs/assets/debugswift_network_network.png"><b>View High-DPI PNG</b></a> • 📝 <a href="docs/assets/debugswift_network_network.seq"><b>View Sequence Source (.seq)</b></a>
</p>

---

### 4. Layman Mode (`--mode layman`)
> Simple, non-technical explanation: How DebugSwift catches mobile app requests before they leave the phone, checks for test settings, and returns instant mock data without using mobile data/WiFi.

```text
/sequify --mode layman How DebugSwift intercepts app traffic for testing
```

<p align="center">
  <img src="docs/assets/debugswift_network_layman.png" alt="Layman Mode DebugSwift Traffic Interception Sequence Diagram" width="100%">
</p>

<p align="center">
  📄 <a href="docs/assets/debugswift_network_layman.pdf"><b>Download Vector PDF</b></a> • 🖼️ <a href="docs/assets/debugswift_network_layman.png"><b>View High-DPI PNG</b></a> • 📝 <a href="docs/assets/debugswift_network_layman.seq"><b>View Sequence Source (.seq)</b></a>
</p>

---

### 5. Hand-Drawn Sketch Theme (`--theme hand`)
> Expressive whiteboard sketch styling with embedded Architects Daughter font for team onboarding, architecture walkthroughs, and RFC reviews.

```text
/sequify --theme hand DebugSwift Network Injection Architecture overview
```

<p align="center">
  <img src="docs/assets/debugswift_network_hand.png" alt="Hand-Drawn Theme DebugSwift Network Architecture Diagram" width="100%">
</p>

<p align="center">
  📄 <a href="docs/assets/debugswift_network_hand.pdf"><b>Download Vector PDF</b></a> • 🖼️ <a href="docs/assets/debugswift_network_hand.png"><b>View High-DPI PNG</b></a> • 📝 <a href="docs/assets/debugswift_network_hand.seq"><b>View Sequence Source (.seq)</b></a>
</p>

---

## 🔒 Security & Privacy

Sequify is built from the ground up adhering to enterprise AI skill security best practices:
- **⚡ 100% Local & Offline**: All rendering is executed locally via macOS WebKit without any outbound network calls or cloud telemetry.
- **🛡️ Cryptographic Subresource Integrity (SRI)**: All bundled offline vendor scripts (`Snap.svg`, `Underscore`, `js-sequence-diagrams`) and fonts are verified against hardcoded SHA-256 cryptographic checksums before DOM injection.
- **📦 Zero-Binary Source Distribution**: Repositories ship strictly as clean, transparent Swift source code (`render_diagram.swift`), eliminating untrusted precompiled binary risks.
- **🔒 Sandboxed & Escaped**: Diagram inputs are size-bounded (max 512 KB) and serialized via strict JSON boundaries to prevent script breakout, HTML injection, or command tampering.
- **🔑 Privacy-Preserving API Documentation**: Skill rules strictly mandate the redaction of real authorization tokens, bearer credentials, and cryptographic signatures.
- **🎯 Code as Sole Source of Truth**: Diagrams and architectural specifications are strictly verified against actual codebase files, eliminating speculative, assumed, or fabricated flows.

---

## 🏗️ Repository Architecture

```text
sequify/
├── install.sh                  # One-click installer (Global / Workspace)
├── uninstall.sh                # Clean uninstaller script
├── LICENSE                     # MIT License & 3rd-party notices
├── README.md                   # Project documentation
└── sequify/                    # Antigravity skill package
    ├── SKILL.md                # Skill prompt & agent execution workflow
    ├── resources/
    │   ├── template.html       # Standalone HTML viewer template
    │   └── vendor/             # Bundled offline JS & Font (~160 KB total)
    │       ├── ArchitectsDaughter-Regular.ttf
    │       ├── snap.svg-min.js
    │       ├── underscore-min.js
    │       ├── sequence-diagram-snap-min.js
    │       └── svginnerhtml.min.js
    └── scripts/
        ├── render_diagram.swift # Swift WebKit headless renderer (with SHA-256 SRI)
        └── compile.sh           # Local compilation helper
```

---

## 🗑️ Uninstallation

```bash
# If installed via npx skills:
npx skills remove sequify -g

# If installed via install.sh:
./uninstall.sh
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

### Third-Party Acknowledgements
- [js-sequence-diagrams](https://bramp.github.io/js-sequence-diagrams/) by Andrew Brampton (Simplified BSD License)
- [Snap.svg](https://snapsvg.io/) by Adobe Systems Inc. (Apache 2.0)
- [Underscore.js](https://underscorejs.org/) (MIT License)
- [Architects Daughter Font](https://fonts.google.com/specimen/Architects+Daughter) by Kimberly Geswein (SIL Open Font License 1.1)
