# Product Requirement Document (PRD)
## Multi-Session Mobile SSH Client ("PocketOps")

---

## 1. Document Control & Metadata
- **Product Name:** PocketOps (Internal Codename: SecureShell Mobile)
- **Document Version:** 1.0.0
- **Status:** Draft / Ready for Review
- **Author:** Lead Product Architect / Mobile Engineer
- **Target Launch:** Q3 2026
- **Primary Tech Stack:** Flutter, Dart, `dartssh2`, `xterm` (Flutter), SQLite, Hardware Keystore / Secure Storage

---

## 2. Executive Summary & Objective

### 2.1 The Problem
Engineers, devops professionals, and security-conscious system administrators frequently need to triage server alerts, inspect production workloads, or reboot services while away from their primary workstation. Existing commercial SSH applications (e.g., Termius, JuiceSSH) are proprietary, often rely on cloud synchronization for credentials, and introduce potential supply chain or telemetry vectors.

### 2.2 The Solution
**PocketOps** is a lightweight, zero-cloud-telemetry, open-architecture mobile application built with Flutter. It allows users to authenticate to remote servers (e.g., AWS EC2, bare-metal nodes) using local hardware-backed private keys, interact with remote shells via an interactive terminal, and seamlessly switch between multiple concurrent live sessions without dropping connection state.

### 2.3 Target Audience
- System Administrators & Site Reliability Engineers (SREs).
- Cloud Engineers managing EC2, GCP Compute Engine, or VPS infrastructure.
- Privacy/security-minded developers requiring self-audited mobile access.

---

## 3. Goals & Success Metrics

| Goal | Success Metric (KPI) | Target |
| :--- | :--- | :--- |
| **Connection Stability** | Session drop rate during background app switching (< 3 mins) | < 2% unexpected terminations |
| **Low Latency** | Time-to-Shell (launch app $\rightarrow$ open active shell) | $< 1.8$ seconds on 5G/Wi-Fi |
| **Zero Key Leakage** | Plaintext key presence on local disk or unencrypted memory buffers | 0 instances (enforced by OS Keystore) |
| **Multi-tasking Efficiency** | Live session switch time | $< 100$ ms transition without re-render lag |

---

## 4. User Personas & Core Workflows

### 4.1 Persona: Alex (DevOps Engineer on Call)
- **Behavior:** Gets paged by PagerDuty while commuting.
- **Pain Point:** Reluctant to import sensitive corporate keys into third-party closed-source apps; needs quick access to run diagnostic commands (`systemctl status`, `docker logs`) without losing session state if switching between 2-3 cluster nodes.
- **Core Need:** Fast, multi-server tabbed navigation and an easy-access mobile keyboard bar for keys like `Ctrl+C`, `Esc`, and Tab.

### 4.2 Key User Journeys
1. **Server Provisioning:** Add a new server profile $\rightarrow$ specify Host, Port, Username $\rightarrow$ paste/import `.pem` or `id_ed25519` key $\rightarrow$ verify & pin host key fingerprint (TOFU).
2. **Interactive Triage:** Connect to Server A $\rightarrow$ launch interactive PTY $\rightarrow$ execute commands with accessory bar $\rightarrow$ switch to Server B from drawer $\rightarrow$ switch back to Server A with command outputs preserved.
3. **Emergency Disconnect:** Terminate individual or all active SSH sockets with one tap.

---

## 5. Functional Requirements

### 5.1 Connection & Protocol Management
- **FR-1.1:** The app **must** support SSHv2 protocol via `dartssh2`.
- **FR-1.2:** Authentication methods **must** include:
  - Ed25519, RSA, and ECDSA key pairs (with or without passphrases).
  - Password authentication (optional, fallback).
- **FR-1.3:** The app **must** support automated SSH keep-alives (configurable ping interval, default 15s) to prevent cellular carrier NAT timeouts.
- **FR-1.4:** Connection timeout handling: graceful UI retry state if connection is unreachable within 10 seconds.

### 5.2 Interactive Terminal Emulator
- **FR-2.1:** Terminal output **must** support ANSI 256-color codes, cursor navigation, and standard text formatting via `xterm.dart`.
- **FR-2.2:** Real-time PTY window resizing: terminal grid must recalculate rows/columns when:
  - The software keyboard appears or disappears.
  - The device orientation changes (Portrait $\leftrightarrow$ Landscape).
- **FR-2.3:** Configurable scrollback history buffer (default: 5,000 lines).
- **FR-2.4:** Dedicated Mobile Accessory Row: persistent toolbar above the virtual keyboard providing quick access to:
  - `ESC`, `TAB`, `CTRL`, `ALT`.
  - Directional navigation (`▲`, `▼`, `◄`, `►`).
  - Common shell sequences: `Ctrl+C`, `Ctrl+D`, `Ctrl+Z`, `|` (pipe), `~`, `/`.

### 5.3 Multi-Session Multiplexing
- **FR-3.1:** The app **must** support multiple simultaneous active SSH connections.
- **FR-3.2:** Sessions **must** run decoupled from the UI view lifecycle so switching views does not disconnect or clear terminal history.
- **FR-3.3:** Tab/Drawer switcher must display real-time connection status badges (Connected, Connecting, Disconnected, Error).

### 5.4 Server & Profile Management
- **FR-4.1:** CRUD operations for server profiles (Label, Host/IP, Port, Username, Associated Key Alias).
- **FR-4.2:** "Recent Servers" list sorted by `last_connected_at` timestamp.
- **FR-4.3:** Profile search and filtering by label or IP address.

---

## 6. Non-Functional & Security Requirements

### 6.1 Security & Cryptography
- **NFR-1.1 (Key Storage):** All private keys **must** be stored exclusively in `FlutterSecureStorage` (backed by iOS Keychain and Android Keystore with Hardware-backed Keystore / StrongBox flags enabled where available).
- **NFR-1.2 (Biometric Lock):** App open and key-usage operations can optionally require local biometric validation (Face ID / Fingerprint).
- **NFR-1.3 (Host Key Pinning):** Implement Trust-On-First-Use (TOFU). On first connect, prompt the user with the server's public key fingerprint. Pin the fingerprint in SQLite. Reject connections if the fingerprint changes unexpectedly (MITM protection).
- **NFR-1.4 (Zero Telemetry):** No analytics, third-party trackers, crash-reporting SDKs, or external network requests outside the user-initiated SSH sockets.

### 6.2 Performance & Responsiveness
- **NFR-2.1:** Terminal rendering must sustain 60 FPS scrolling even with rapid text output (e.g., running `top` or streaming fast logs).
- **NFR-2.2:** App binary size should remain below 25 MB on Android (APK) and iOS (IPA).

### 6.3 Reliability & Lifecycle
- **NFR-3.1:** Graceful handling of Android/iOS app sleep cycles. If the OS kills a background socket, the UI must flag the session as "Interrupted" and allow 1-tap reconnect rather than crashing.

---

## 7. Data Models & Schemas

### 7.1 Server Profile (SQLite)
```sql
CREATE TABLE servers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    host TEXT NOT NULL,
    port INTEGER NOT NULL DEFAULT 22,
    username TEXT NOT NULL,
    key_alias TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    last_connected_at INTEGER
);
```

### 7.2 Known Hosts (SQLite)
```sql
CREATE TABLE known_hosts (
    host TEXT NOT NULL,
    port INTEGER NOT NULL,
    key_type TEXT NOT NULL,
    fingerprint TEXT NOT NULL,
    first_seen_at INTEGER NOT NULL,
    PRIMARY KEY (host, port)
);
```

### 7.3 Secure Storage Key Schema
- Key: `key_payload_{key_alias}` $\rightarrow$ Value: Encrypted OpenSSH PEM string.
- Key: `key_pass_{key_alias}` $\rightarrow$ Value: Optional encrypted passphrase.

---

## 8. Release Milestones & Phase Breakdown

```
Phase 1: Core Shell (Weeks 1-3)
├── dartssh2 integration with hardcoded server
├── xterm.dart terminal rendering & PTY resizing
└── Keyboard accessory bar (ESC, TAB, Ctrl)

Phase 2: Persistence & Security (Weeks 4-5)
├── SQLite database for server profiles
├── FlutterSecureStorage integration for PEM keys
└── Host key TOFU verification dialog

Phase 3: Multi-Session State (Weeks 6-7)
├── SessionManager state singleton
├── Drawer/Tab switcher for active live connections
└── Background keep-alive & reconnect handling

Phase 4: Hardening & Testing (Week 8)
├── Security audit (memory dumping & Keystore tests)
├── Terminal rendering benchmarks (large buffers)
└── Release candidate packaging
```

---

## 9. Risks & Mitigations

| Risk | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Mobile OS kills background sockets** | High | Inform users via banner; send periodic SSH NOOP/ping packets; on Android, offer an optional foreground notification service. |
| **Terminal resizing glitches** | Medium | Hook directly into `terminal.onResize` and propagate dimensions via `SSHPtyConfig.resizeTerminal()` immediately upon viewport change. |
| **Passphrase theft via memory inspection** | High | Clear plaintext key buffers from memory as soon as the `SSHKeyPair` object is created and authenticated. |