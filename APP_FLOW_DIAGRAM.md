# File Cryptor - Complete Application Flow & Specs

## 🔐 Complete Application Flow

```mermaid
graph TD
    Start([Launch App]) --> CheckAuth{Logged In?}

    %% Authentication Flow
    CheckAuth -->|No| Login[Login/Register]
    Login --> VerifyEmail[Verify Email]
    VerifyEmail --> Home[Home Screen]
    CheckAuth -->|Yes| Home

    %% Main Navigation
    Home --> Choose{Choose Action}
    Choose -->|Encrypt| Encrypt[Encrypt Files]
    Choose -->|Decrypt| Decrypt[Decrypt Files]
    Choose -->|Profile| Profile[Profile/Logout]

    %% Encryption Flow
    Encrypt --> E1[1. Select File]
    E1 --> E2[2. Enter Password]
    E2 --> E3[3. Encrypt File]
    E3 --> E4[4. Save/Share/Upload]
    E4 --> Home

    %% Decryption Flow
    Decrypt --> D1[1. Select Encrypted File<br/>Local or Cloud]
    D1 --> D2[2. Enter Password]
    D2 --> D3[3. Decrypt File]
    D3 --> D4[4. Save to Downloads]
    D4 --> Home

    %% Profile Flow
    Profile --> Logout[Logout]
    Logout --> Login

    %% Better contrast colors with white text
    style Start fill:#2e7d32,stroke:#1b5e20,stroke-width:3px,color:#fff
    style Home fill:#1565c0,stroke:#0d47a1,stroke-width:3px,color:#fff
    style Encrypt fill:#f57c00,stroke:#e65100,stroke-width:3px,color:#fff
    style Decrypt fill:#c62828,stroke:#b71c1c,stroke-width:3px,color:#fff
    style Profile fill:#6a1b9a,stroke:#4a148c,stroke-width:3px,color:#fff
    style Login fill:#2e7d32,stroke:#1b5e20,stroke-width:3px,color:#fff
    style VerifyEmail fill:#558b2f,stroke:#33691e,stroke-width:3px,color:#fff

    style CheckAuth fill:#424242,stroke:#212121,stroke-width:2px,color:#fff
    style Choose fill:#424242,stroke:#212121,stroke-width:2px,color:#fff

    style E1 fill:#ef6c00,stroke:#e65100,stroke-width:2px,color:#fff
    style E2 fill:#ef6c00,stroke:#e65100,stroke-width:2px,color:#fff
    style E3 fill:#ef6c00,stroke:#e65100,stroke-width:2px,color:#fff
    style E4 fill:#ef6c00,stroke:#e65100,stroke-width:2px,color:#fff

    style D1 fill:#d32f2f,stroke:#b71c1c,stroke-width:2px,color:#fff
    style D2 fill:#d32f2f,stroke:#b71c1c,stroke-width:2px,color:#fff
    style D3 fill:#d32f2f,stroke:#b71c1c,stroke-width:2px,color:#fff
    style D4 fill:#d32f2f,stroke:#b71c1c,stroke-width:2px,color:#fff

    style Logout fill:#7b1fa2,stroke:#4a148c,stroke-width:2px,color:#fff
```

---

## 🔐 Encryption Process (Detailed Diagram)

```mermaid
flowchart TD
    subgraph Encryption Process
      SE([Start Encryption]) --> SF[Select File<br/>(single or multiple)]
      SF --> FV{File Valid?}
      FV -->|No| ERR1[Show Error: Invalid/Unreadable File]
      ERR1 --> ENDERR([Abort])
      FV -->|Yes| PA[Password / Passphrase or Key Input]
      PA --> CH{Choose Mode}
      CH -->|Password-based| KDF[Generate Salt & Derive Key<br/>(PBKDF2 / Argon2)]
      CH -->|Key / Public Key| KEYREADY[Use Provided Key / Hybrid RSA wrap]
      KDF --> IVGEN[Generate IV / Nonce]
      KEYREADY --> IVGEN
      IVGEN --> ALG[Select Algorithm<br/>AES-256-GCM / ChaCha20-Poly1305 / Custom]
      ALG --> STREAM{Large file?}
      STREAM -->|Yes| STREAM_ENC[Stream encrypt in chunks<br/>(read → encrypt → write)]
      STREAM -->|No| BUF_ENC[Buffer & encrypt whole file]
      STREAM_ENC --> AUTH[Compute Auth Tag / MAC]
      BUF_ENC --> AUTH
      AUTH --> PACKAGE[Create Package: ciphertext + salt + iv + tag + metadata]
      PACKAGE --> SIGN[Optional: Sign or compute checksum (SHA-256)]
      SIGN --> SAVEOPT{Save / Share / Upload}
      SAVEOPT -->|Save Local| SAVELOC[Save to chosen destination]
      SAVEOPT -->|Share| SHARE[Open share dialog / copy link]
      SAVEOPT -->|Upload| UPLOAD[Upload to cloud provider]
      SAVELOC --> SUCCESS[Show Success / Provide file info]
      SHARE --> SUCCESS
      UPLOAD --> SUCCESS
      ERR2[Encryption Error] --> ENDERR
      AUTH -->|Error| ERR2
      SUCCESS --> END([End])
    end

    %% Styling
    style SE fill:#2e7d32,stroke:#1b5e20,color:#fff
    style SF fill:#1976d2,stroke:#0d47a1,color:#fff
    style FV fill:#424242,stroke:#212121,color:#fff
    style PA fill:#ef6c00,stroke:#e65100,color:#fff
    style KDF fill:#6a1b9a,stroke:#4a148c,color:#fff
    style KEYREADY fill:#6a1b9a,stroke:#4a148c,color:#fff
    style IVGEN fill:#c62828,stroke:#b71c1c,color:#fff
    style ALG fill:#0d47a1,stroke:#0a3d91,color:#fff
    style STREAM_ENC fill:#f57c00,stroke:#e65100,color:#fff
    style BUF_ENC fill:#f57c00,stroke:#e65100,color:#fff
    style AUTH fill:#4caf50,stroke:#388e3c,color:#fff
    style PACKAGE fill:#29b6f6,stroke:#0288d1,color:#fff
    style SIGN fill:#8e24aa,stroke:#6a1b9a,color:#fff
    style SAVEOPT fill:#424242,stroke:#212121,color:#fff
    style SAVELOC fill:#2e7d32,stroke:#1b5e20,color:#fff
    style SHARE fill:#1565c0,stroke:#0d47a1,color:#fff
    style UPLOAD fill:#7b1fa2,stroke:#4a148c,color:#fff
    style SUCCESS fill:#2e7d32,stroke:#1b5e20,color:#fff
    style ERR1 fill:#b71c1c,stroke:#7f0000,color:#fff
    style ERR2 fill:#b71c1c,stroke:#7f0000,color:#fff
```

---

## 🔑 Key Components (Updated)

- Encryption Service

  - File Key Generation: Random 32-byte key per file (file encryption key, FEK)
  - Password Derivation:
    - Current spec: PBKDF2 with 1000 iterations (salted)
    - Note: 1000 iterations is weak by modern standards; consider increasing iterations and/or using Argon2id for better resistance to GPU attacks.
  - Encryption Algorithm:
    - Current spec: AES-256-CBC (authenticated mode recommended, e.g., AES-256-GCM)
    - For integrity protection, prefer AEAD (AES-GCM or ChaCha20-Poly1305). If CBC is used, add HMAC (e.g., HMAC-SHA256) over ciphertext and metadata.
  - Double Encryption:
    - FEK encrypts file data
    - FEK wrapped/encrypted with user-derived key (KDF result)
  - File Structure:
    - Custom container including header metadata (version, cipher, kdf, kdf_params, salt, iv/nonce, tag/mac, ciphertext, optional signature/checksum)

- Authentication Service (Supabase)

  - Email/password auth with required email confirmation
  - Session tokens, refresh handling, and auth-state stream via Supabase client
  - Resend confirmation flow, password reset

- Storage Service

  - Local storage (Downloads folder) for final decrypted/encrypted files
  - Supabase Storage integration for cloud uploads/downloads
  - Temporary file handling during streaming and chunked operations

- Database Models

EncryptedFile:

- id: UUID
- fileName: String
- filePath: String (local path or cloud URL)
- userId: String (foreign key to Users)
- uploadedAt: DateTime
- metadata: JSON (version, cipher, kdf, salt, iv, tag, chunking info, original file size, checksum)

Example JSON metadata (example):

```json
{
  "version": "1.0",
  "cipher": "AES-256-GCM",
  "kdf": "PBKDF2",
  "kdf_params": {
    "iterations": 1000,
    "salt": "base64..."
  },
  "iv": "base64...",
  "tag": "base64...",
  "chunk_size": 65536,
  "original_size": 1234567,
  "checksum": "sha256:..."
}
```

---

## 🛡️ Security Features (Summary & Recommendations)

1. Double Encryption
   - FEK (random per file) + FEK wrapped with user-derived key
2. Password Security
   - PBKDF2 currently with 1000 iterations (salted)
   - Recommendation: Raise iterations (e.g., 100k+) or switch to Argon2id with memory and time cost parameters
3. Encryption Mode
   - Current: AES-256-CBC — ensure you include HMAC for integrity, or migrate to AEAD (AES-GCM / ChaCha20-Poly1305)
4. Email Verification & Session Management
   - Email verification before access
   - Automatic logout on token expiry
   - Secure token storage (OS-backed secure storage)
5. Metadata & Versioning
   - Embed explicit version numbers so future changes to format and algorithms remain compatible

---

## 📱 User Experience Flow (Concise)

Login → Home Screen (3 Tabs)
├─ Encrypt: Pick File → Set Password → Encrypt → Save/Share/Upload  
├─ Decrypt: Pick File/Cloud File → Enter Password → Decrypt → Save  
└─ Profile: View Info → Logout

---

## Files & Deliverables Included

This single Markdown file contains:

- App flow mermaid diagram
- Detailed encryption process mermaid diagram
- Updated key components and DB model
- Security summary and recommendations
- UX flow summary

---

What I did: I packaged the complete, updated application flow and the detailed encryption process into a single Markdown file containing both diagrams and clear technical/spec details so you can drop it into your repo or documentation.

What's next: I can (pick one)

- produce a complementary decryption diagram that mirrors the encryption package (with parsing/verifying metadata),
- convert these mermaid diagrams into PNG/SVG files and attach them,
- generate a machine-readable JSON/YAML schema for the EncryptedFile metadata,
- or update the spec to use stronger KDF/AEAD defaults and produce migration notes.

Tell me which of those you'd like me to do next and I'll proceed.
