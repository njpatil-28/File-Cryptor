# File Cryptor - Complete Application Flow Diagram

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

## 📋 Detailed Flow Descriptions

### 1. **Authentication Flow**

```

## 🔑 Key Components

### **Encryption Service**

- **File Key Generation**: Random 32-byte key per file
- **Password Derivation**: PBKDF2 with 1000 iterations
- **Encryption Algorithm**: AES-256 CBC mode
- **File Structure**: Custom format with embedded metadata

### **Authentication Service (Supabase)**

- User registration with email confirmation
- Email/password authentication
- Session management
- Auth state streaming

### **Storage Service**

- Local file storage (Downloads folder)
- Supabase Storage for cloud uploads
- Temporary file handling

### **Database Models**

```

EncryptedFile:

- id (UUID)
- fileName (String)
- filePath (String)
- userId (String)
- uploadedAt (DateTime)
- metadata (String, optional)

```

## 🛡️ Security Features

1. **Double Encryption**:

   - Random file key per file
   - File key encrypted with user password

2. **Password Security**:

   - PBKDF2 key derivation
   - 1000 iterations
   - Salted hashing

3. **Email Verification**:

   - Required before access
   - Resend capability

4. **Session Management**:
   - Automatic logout on token expiry
   - Secure token storage

## 📱 User Experience Flow

```

Login → Home Screen (3 Tabs)
├─ Encrypt: Pick File → Set Password → Encrypt → Save/Share/Upload
├─ Decrypt: Pick File/Cloud File → Enter Password → Decrypt → Save
└─ Profile: View Info → Logout

```

---

**Note**: All file operations maintain original filenames and extensions through the encryption/decryption cycle.
```
