# PatentGuard - Intellectual Property Filing System

A decentralized smart contract for securing patent priority dates and invention records on the Stacks blockchain. PatentGuard provides cryptographic proof of invention timing, enabling inventors to establish priority dates for their intellectual property in a transparent and immutable manner.

## 🛡️ Overview

PatentGuard revolutionizes intellectual property protection by leveraging blockchain technology to create tamper-proof records of invention filings. By storing cryptographic hashes (digests) of inventions along with precise timestamps, inventors can establish clear priority dates that are verifiable and cannot be disputed.

## 🌟 Key Features

- **Cryptographic Proof**: SHA-256 hashes ensure invention integrity
- **Immutable Timestamps**: Blockchain-based priority date establishment
- **Decentralized Filing**: No central authority required for basic filings
- **Inventor Tracking**: Complete filing history per inventor
- **Batch Operations**: Efficient lookup of multiple inventions
- **Privacy Protection**: Only hash stored on-chain, not invention details
- **Administrative Oversight**: Patent office access for regulatory compliance

## 📊 Contract Architecture

### Constants
- **Patent Office**: Contract deployer with administrative privileges
- **Error Codes**: 400-403 range for IP-specific errors

### Core Data Structures

#### Invention Archive
```clarity
{
  digest: (buff 32),           // SHA-256 hash of invention
  inventor: principal,         // Inventor's Stacks address
  filing-date: uint,          // Unix timestamp of filing
  priority-block: uint,       // Block height at filing
  invention-summary: string   // Brief description (256 chars max)
}
```

#### Inventor Tracking
- **inventor-filings**: Maps inventor + filing ID to invention digest
- **inventor-filing-count**: Tracks total filings per inventor
- **total-inventions**: Global counter of all filings

## 🚀 Core Functions

### Filing Functions

#### `file-invention`
```clarity
(file-invention (digest (buff 32)) (invention-summary (string-ascii 256)))
```
File a new invention with cryptographic proof and priority date.

**Parameters:**
- `digest`: SHA-256 hash of the invention (32 bytes)
- `invention-summary`: Brief description of the invention (max 256 characters)

**Returns:**
```clarity
{
  digest: (buff 32),
  inventor: principal,
  filing-date: uint,
  priority-block: uint,
  filing-id: uint
}
```

**Requirements:**
- Digest must be exactly 32 bytes (valid SHA-256)
- Invention digest must not already exist
- Summary must not exceed 256 ASCII characters

#### Example Usage
```clarity
;; Generate SHA-256 hash of your invention document
(define-constant my-invention-hash 0x1a2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890)

;; File the invention
(contract-call? .patentguard file-invention 
  my-invention-hash 
  "Novel quantum computing algorithm for optimization")
```

### Lookup Functions

#### `lookup-invention`
```clarity
(lookup-invention (digest (buff 32)))
```
Retrieve filing information for a specific invention digest.

**Parameters:**
- `digest`: SHA-256 hash of the invention

**Returns:** Complete invention filing record or error

#### `get-invention-by-filing-id`
```clarity
(get-invention-by-filing-id (inventor principal) (filing-id uint))
```
Retrieve invention by inventor and sequential filing ID.

**Parameters:**
- `inventor`: Stacks address of the inventor
- `filing-id`: Sequential ID of the filing (starts from 1)

#### `batch-lookup`
```clarity
(batch-lookup (digests (list 10 (buff 32))))
```
Look up multiple inventions in a single call (max 10).

**Parameters:**
- `digests`: List of up to 10 SHA-256 hashes

### Statistics Functions

#### `get-inventor-filing-count`
```clarity
(get-inventor-filing-count (inventor principal))
```
Get total number of filings by a specific inventor.

#### `get-total-inventions`
```clarity
(get-total-inventions)
```
Get total number of inventions filed in the system.

#### `get-office-stats`
```clarity
(get-office-stats)
```
Get system statistics including total inventions and patent office address.

### Verification Functions

#### `is-invention-inventor`
```clarity
(is-invention-inventor (digest (buff 32)) (user principal))
```
Verify if a specific user is the inventor of a given invention.

## 💡 Usage Examples

### Basic Invention Filing
```clarity
;; Step 1: Create your invention document
;; Step 2: Generate SHA-256 hash offline
;; Step 3: File with PatentGuard

(contract-call? .patentguard file-invention 
  0x4a5b6c7d8e9f0123456789abcdef0123456789abcdef0123456789abcdef0123
  "Improved solar panel efficiency using nanomaterials")
```

### Verify Invention Priority
```clarity
;; Look up an invention to verify priority date
(contract-call? .patentguard lookup-invention 
  0x4a5b6c7d8e9f0123456789abcdef0123456789abcdef0123456789abcdef0123)

;; Returns:
;; {
;;   inventor: 'SP2EXAMPLE...INVENTOR,
;;   filing-date: u1640995200, ;; Unix timestamp
;;   priority-block: u12345,   ;; Block height
;;   invention-summary: "Improved solar panel efficiency..."
;; }
```

### Batch Verification
```clarity
;; Verify multiple inventions at once
(contract-call? .patentguard batch-lookup (list
  0x4a5b6c7d8e9f0123456789abcdef0123456789abcdef0123456789abcdef0123
  0x5b6c7d8e9f0123456789abcdef0123456789abcdef0123456789abcdef012345
  0x6c7d8e9f0123456789abcdef0123456789abcdef0123456789abcdef01234567
))
```

### Inventor Portfolio Review
```clarity
;; Check how many inventions an inventor has filed
(contract-call? .patentguard get-inventor-filing-count 'SP2EXAMPLE...INVENTOR)

;; Get specific invention by filing ID
(contract-call? .patentguard get-invention-by-filing-id 
  'SP2EXAMPLE...INVENTOR 
  u3) ;; Third invention filed by this inventor
```

## 🔐 Security Features

### Cryptographic Integrity
- **SHA-256 Hashing**: Industry-standard cryptographic hashing
- **32-byte Validation**: Ensures proper hash format
- **Immutable Records**: Blockchain ensures records cannot be altered

### Access Control
- **Inventor Verification**: Only inventors can file their own inventions
- **Administrative Access**: Patent office has read-only administrative access
- **Privacy Protection**: Only hashes stored, not full invention details

### Anti-Fraud Protection
- **Duplicate Prevention**: Same invention digest cannot be filed twice
- **Timestamp Integrity**: Block height and timestamp provide dual verification
- **Transparent History**: Complete filing history available for verification

## ⚠️ Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 400 | ERR-PERMISSION-DENIED | Unauthorized access to administrative functions |
| 401 | ERR-INVENTION-FILED | Invention digest already exists in the system |
| 402 | ERR-INVENTION-NOT-FOUND | Requested invention digest not found |
| 403 | ERR-INVALID-DIGEST | Invalid digest format (must be 32 bytes) |

## 🛠️ Integration Guide

### For Patent Management Systems
```javascript
// Generate SHA-256 hash of invention document
const crypto = require('crypto');
const inventionDocument = fs.readFileSync('invention.pdf');
const hash = crypto.createHash('sha256').update(inventionDocument).digest();

// Convert to Clarity buffer format
const clarityHash = `0x${hash.toString('hex')}`;

// File with PatentGuard
const fileResult = await callContractFunction({
  contractAddress: 'SP2EXAMPLE...PATENTGUARD',
  contractName: 'patentguard',
  functionName: 'file-invention',
  functionArgs: [
    bufferFromHex(clarityHash),
    stringAsciiCV("Revolutionary AI algorithm for drug discovery")
  ]
});
```

### For Legal Tech Applications
```javascript
// Verify invention priority for legal proceedings
async function verifyInventionPriority(inventionHash) {
  const result = await callReadOnlyFunction({
    contractAddress: 'SP2EXAMPLE...PATENTGUARD',
    contractName: 'patentguard',
    functionName: 'lookup-invention',
    functionArgs: [bufferFromHex(inventionHash)]
  });
  
  if (result.type === 'ok') {
    const filingInfo = result.value;
    return {
      inventor: filingInfo.inventor,
      filingDate: new Date(filingInfo.filing_date * 1000),
      priorityBlock: filingInfo.priority_block,
      summary: filingInfo.invention_summary
    };
  }
  
  throw new Error('Invention not found');
}
```

### For Research Institutions
```clarity
;; Institutional filing contract
(define-public (institutional-filing (invention-hash (buff 32)) (researcher principal) (project-id uint))
  (begin
    ;; Verify researcher is affiliated with institution
    (asserts! (is-authorized-researcher researcher) err-unauthorized)
    
    ;; File invention through PatentGuard
    (try! (contract-call? .patentguard file-invention 
      invention-hash 
      (concat "Institutional Research Project #" (int-to-ascii project-id))))
    
    ;; Record institutional metadata
    (map-set institutional-filings
      { hash: invention-hash }
      { researcher: researcher, project: project-id })
    
    (ok true)
  )
)
```

## 📋 Best Practices

### Invention Documentation
1. **Complete Documentation**: Maintain detailed invention records offline
2. **Secure Hashing**: Use secure, deterministic hashing methods
3. **Backup Storage**: Store original documents and hashes securely
4. **Version Control**: Track invention evolution with dated versions

### Filing Strategy
1. **Early Filing**: File as soon as invention concept is complete
2. **Comprehensive Summaries**: Use full 256 characters for descriptions
3. **Batch Processing**: Use batch lookup for portfolio management
4. **Regular Monitoring**: Monitor filing status and system statistics

### Legal Considerations
1. **Jurisdictional Compliance**: Ensure compliance with local patent laws
2. **Professional Advice**: Consult IP attorneys for complex cases
3. **Documentation Trail**: Maintain complete records for legal proceedings
4. **International Filing**: Consider international patent protection strategies

## 🏛️ Legal Framework Integration

### Patent Priority Evidence
PatentGuard filings can serve as evidence in patent disputes:
- **Prior Art Searches**: Establish invention dates for prior art analysis
- **Priority Claims**: Support patent application priority claims
- **Dispute Resolution**: Provide immutable evidence in IP disputes
- **Licensing Negotiations**: Establish invention timeline for licensing

### Regulatory Compliance
- **Patent Office Integration**: Administrative access for regulatory oversight
- **Audit Trails**: Complete filing history for compliance audits
- **Cross-Border Recognition**: Blockchain records for international cases
- **Standard Compliance**: Compatible with emerging blockchain IP standards

## 🌍 Use Cases

### Individual Inventors
- **Hobby Inventors**: Protect weekend projects and innovations
- **Independent Researchers**: Establish priority for research discoveries
- **Startup Founders**: Secure IP before seeking investment
- **Academic Researchers**: Protect research prior to publication

### Enterprises
- **R&D Departments**: Systematic invention filing workflows
- **Patent Portfolios**: Manage large invention portfolios
- **IP Strategy**: Support comprehensive IP protection strategies
- **Competitive Intelligence**: Monitor competitor filing activity

### Legal Professionals
- **Patent Attorneys**: Evidence gathering for patent applications
- **IP Litigation**: Priority evidence for legal proceedings
- **Due Diligence**: IP asset verification for transactions
- **Patent Prosecution**: Support patent application processes

### Research Institutions
- **Universities**: Protect research before publication
- **Labs**: Systematic invention documentation
- **Collaborative Research**: Multi-party invention priority
- **Technology Transfer**: Support commercialization efforts

## 🚨 Risk Considerations

### Technical Risks
- **Hash Collision**: Extremely rare but theoretically possible
- **Key Management**: Secure management of inventor private keys
- **Network Availability**: Dependence on Stacks blockchain availability
- **Smart Contract Bugs**: Code vulnerabilities (recommend auditing)

### Legal Risks
- **Jurisdictional Variations**: Different patent laws across jurisdictions
- **Evidence Admissibility**: Blockchain evidence acceptance varies
- **Professional Liability**: Not a substitute for professional legal advice
- **Regulatory Changes**: Evolving regulations around blockchain IP

### Operational Risks
- **Filing Errors**: Incorrect hashes or summaries cannot be corrected
- **Privacy Concerns**: Invention summaries are public
- **Cost Considerations**: Transaction fees for filing operations
- **Scalability**: Network congestion may delay filings

 resea
