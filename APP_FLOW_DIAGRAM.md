# File Cryptor - Complete Application Flow Diagram

## 🔐 Complete Application Flow

```mermaid
graph TD
    Start([App Launch]) --> Init[Initialize Supabase]
    Init --> AuthCheck{Check Auth State}
    
    AuthCheck -->|No Session| LoginScreen[Login Screen]
    AuthCheck -->|Active Session| HomeScreen[Home Screen]
    
    %% Login Flow
    LoginScreen --> LoginChoice{User Action}
    LoginChoice -->|Sign In| ValidateLogin{Validate Credentials}
    LoginChoice -->|Go to Register| RegisterScreen[Register Screen]
    
    ValidateLogin -->|Invalid| LoginError[Show Error Message]
    LoginError --> LoginScreen
    ValidateLogin -->|Valid but Unconfirmed| EmailConfScreen[Email Confirmation Screen]
    ValidateLogin -->|Valid & Confirmed| HomeScreen
    
    %% Registration Flow
    RegisterScreen --> RegValidate{Validate Input}
    RegValidate -->|Password Mismatch| RegError[Show Error]
    RegError --> RegisterScreen
    RegValidate -->|Valid| CreateAccount[Create Supabase Account]
    CreateAccount --> GenEncKey[Generate Encryption Key]
    GenEncKey --> StoreKey[Store Key in Secure Storage]
    StoreKey --> EmailConfScreen
    
    %% Email Confirmation Flow
    EmailConfScreen --> ConfAction{User Action}
    ConfAction -->|Check Status| VerifyEmail{Email Confirmed?}
    ConfAction -->|Resend Email| ResendConf[Resend Confirmation]
    ConfAction -->|Continue to Login| LoginScreen
    VerifyEmail -->|No| WaitConf[Wait for Confirmation]
    VerifyEmail -->|Yes| LoginScreen
    ResendConf --> EmailConfScreen
    WaitConf --> EmailConfScreen
    
    %% Home Screen Navigation
    HomeScreen --> NavChoice{Bottom Navigation}
    NavChoice -->|Index 0| EncryptScreen[Encrypt Screen]
    NavChoice -->|Index 1| DecryptScreen[Decrypt Screen]
    NavChoice -->|Index 2| ProfileScreen[Profile Screen]
    
    %% Encryption Flow
    EncryptScreen --> EncAction{User Action}
    EncAction -->|Select File| PickFile[File Picker]
    PickFile --> FileSelected[Display File Info]
    FileSelected --> EnterPass[Enter Password & Notes]
    EnterPass --> ValidatePass{Password Valid?}
    ValidatePass -->|No| PassError[Show Error]
    PassError --> EnterPass
    ValidatePass -->|Yes| EncryptProcess[Encryption Process]
    
    %% Encryption Process Details
    EncryptProcess --> GenFileKey[Generate Random File Key]
    GenFileKey --> EncryptData[Encrypt File Data with File Key]
    EncryptData --> EncryptKey[Encrypt File Key with Password]
    EncryptKey --> EmbedMetadata[Embed Filename & Encrypted Key]
    EmbedMetadata --> SaveEncrypted[Save Encrypted File]
    SaveEncrypted --> EncOptions{User Choice}
    
    EncOptions -->|Download| DownloadEnc[Save to Downloads]
    EncOptions -->|Share| ShareEnc[Share via Share Sheet]
    EncOptions -->|Upload to Cloud| CloudUpload[Upload to Supabase Storage]
    
    DownloadEnc --> EncSuccess[Success Message]
    ShareEnc --> EncSuccess
    CloudUpload --> SaveMetadata[Save File Metadata to DB]
    SaveMetadata --> EncSuccess
    EncSuccess --> EncryptScreen
    
    %% Decryption Flow
    DecryptScreen --> DecAction{User Action}
    DecAction -->|Pick Local File| PickEncFile[File Picker - Encrypted File]
    DecAction -->|Select Cloud File| LoadCloudFiles[Load Files from Supabase]
    
    LoadCloudFiles --> CloudFileList[Display Cloud Files]
    CloudFileList --> SelectCloud[Select Cloud File]
    SelectCloud --> DownloadCloud[Download from Storage]
    DownloadCloud --> DecryptDialog[Password Dialog]
    
    PickEncFile --> DecryptDialog
    DecryptDialog --> EnterDecPass[Enter Decryption Password]
    EnterDecPass --> DecryptProcess[Decryption Process]
    
    %% Decryption Process Details
    DecryptProcess --> ExtractMeta[Extract Filename Length & Filename]
    ExtractMeta --> ExtractKeyLen[Extract Encrypted Key Length]
    ExtractKeyLen --> ExtractEncKey[Extract Encrypted File Key]
    ExtractEncKey --> DecryptFileKey[Decrypt File Key with Password]
    DecryptFileKey --> DecKeyValid{Decryption Valid?}
    
    DecKeyValid -->|Invalid| DecError[Wrong Password Error]
    DecError --> DecryptDialog
    DecKeyValid -->|Valid| ExtractIV[Extract IV & Encrypted Data]
    ExtractIV --> DecryptFileData[Decrypt File Data with File Key]
    DecryptFileData --> RestoreOriginal[Restore Original Filename]
    RestoreOriginal --> SaveDecrypted[Save to Downloads]
    SaveDecrypted --> DecSuccess[Success Message]
    DecSuccess --> DecryptScreen
    
    %% Profile Flow
    ProfileScreen --> ProfileAction{User Action}
    ProfileAction -->|Logout| ConfirmLogout{Confirm Logout?}
    ConfirmLogout -->|Yes| SignOut[Sign Out from Supabase]
    ConfirmLogout -->|No| ProfileScreen
    SignOut --> LoginScreen
    
    %% Error Handling
    EncryptProcess -.->|Error| EncError[Show Encryption Error]
    CloudUpload -.->|Error| UploadError[Show Upload Error]
    DecryptProcess -.->|Error| DecryptError[Show Decryption Error]
    EncError --> EncryptScreen
    UploadError --> EncryptScreen
    DecryptError --> DecryptScreen
    
    style Start fill:#e1f5e1
    style HomeScreen fill:#e3f2fd
    style EncryptScreen fill:#fff3e0
    style DecryptScreen fill:#fce4ec
    style ProfileScreen fill:#f3e5f5
    style LoginScreen fill:#e8f5e9
    style RegisterScreen fill:#e8f5e9
    style EmailConfScreen fill:#fff9c4
```

## 📋 Detailed Flow Descriptions

### 1. **Authentication Flow**
```
Start → Initialize Supabase → Check Auth State
    ├─ No Session → Login Screen
    │   ├─ Enter Credentials → Validate
    │   │   ├─ Invalid → Error Message
    │   │   ├─ Valid (Unconfirmed) → Email Confirmation
    │   │   └─ Valid (Confirmed) → Home Screen
    │   └─ Sign Up → Register Screen
    │       ├─ Validate Input (Password Match, etc.)
    │       ├─ Create Account in Supabase
    │       ├─ Generate User Encryption Key
    │       ├─ Store in Secure Storage
    │       └─ Email Confirmation Screen
    │
    └─ Active Session → Home Screen
```

### 2. **Email Confirmation Flow**
```
Email Confirmation Screen
    ├─ Check Status → Verify with Supabase
    │   ├─ Confirmed → Redirect to Login
    │   └─ Not Confirmed → Wait
    ├─ Resend Confirmation → Send New Email
    └─ Continue to Login → Go to Login Screen
```

### 3. **Home Screen Navigation**
```
Home Screen (Bottom Navigation)
    ├─ Encrypt Tab (Index 0) → Encrypt Screen
    ├─ Decrypt Tab (Index 1) → Decrypt Screen
    └─ Profile Tab (Index 2) → Profile Screen
```

### 4. **Encryption Flow (Detailed)**
```
Encrypt Screen
    └─ Select File
        └─ File Picker → Display File Info
            └─ Enter Password (min 6 chars)
                └─ Enter Notes (Optional)
                    └─ Encrypt Button
                        ├─ Generate Random 32-byte File Key
                        ├─ Encrypt File Data with AES-CBC (File Key)
                        ├─ Derive Password Key using PBKDF2
                        ├─ Encrypt File Key with Password Key
                        ├─ Build Structure:
                        │   [4 bytes: filename length]
                        │   [filename bytes]
                        │   [4 bytes: encrypted key length]
                        │   [encrypted key bytes]
                        │   [16 bytes: IV]
                        │   [encrypted file data]
                        └─ Save Encrypted File
                            ├─ Download → Save to Downloads Folder
                            ├─ Share → System Share Sheet
                            └─ Upload to Cloud
                                ├─ Upload to Supabase Storage
                                └─ Save Metadata to Database
```

### 5. **Decryption Flow (Detailed)**
```
Decrypt Screen
    ├─ Pick Local File
    │   └─ File Picker
    │       └─ Password Dialog
    │
    └─ Select Cloud File
        └─ Load from Supabase Database
            └─ Display List of Encrypted Files
                └─ Select File → Download from Storage
                    └─ Password Dialog
                        └─ Decryption Process:
                            ├─ Read Encrypted File Bytes
                            ├─ Extract: [filename length] (4 bytes)
                            ├─ Extract: [filename] (variable)
                            ├─ Extract: [encrypted key length] (4 bytes)
                            ├─ Extract: [encrypted key bytes] (variable)
                            ├─ Extract: [IV] (16 bytes)
                            ├─ Extract: [encrypted data] (remaining)
                            ├─ Derive Password Key (PBKDF2)
                            ├─ Decrypt File Key using Password Key
                            ├─ Decrypt File Data using File Key & IV
                            ├─ Restore Original Filename
                            └─ Save to Downloads
                                └─ Success Message
```

### 6. **Profile Flow**
```
Profile Screen
    ├─ Display User Email
    ├─ Display Member Since Date
    └─ Logout Button
        └─ Confirmation Dialog
            ├─ Cancel → Stay on Profile
            └─ Confirm → Sign Out
                └─ Redirect to Login Screen
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