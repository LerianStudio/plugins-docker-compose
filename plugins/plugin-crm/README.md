# Customer Relationship Management Plugin

## Quick Start

1. **Clone the Repository:**
```bash
git clone https://github.com/LerianStudio/plugins-docker-compose.git
```

2. **Go to the plugin directory:**
```bash
cd plugins/plugin-crm
```
3. **Run the Docker Compose File**
```bash
docker compose up
```
   
5. **Access the API:**
Visit `http://localhost:4003` to interact with the API.

## Data security

### Hashing

Searchable fields are hashed to allow filtering:
- Alias:
  - Document
  - Bank account number
  - Bank IBAN

Obs: The field `document` in the holder collection is not searchable, but is being hashed due to MongoDB unique constraints.

We store these hashes at a separate field in the MongoDB document called `search`:
```plaintext
{
	"_id": "01956b69-9102-75b7-8860-3e75c11d231c",
	...
	"search": {
		"document": "<hmac-hash>",
		...
	}
}
```

Since we use HMAC-SHA256 to generate hashes, a secret key is required. Given the SHA-256 hash function, the recommended key length is 32 bytes.

You can generate this key using the following command:
```bash
openssl rand -hex 32
```

The generated key should be configured for the `LCRYPTO_HASH_SECRET_KEY` environment variable.

### Encryption

The application encrypts the following data because they are sensitive and/or personal:
- Holder:
  - Name
  - Document
  - E-mails
  - Phone numbers
  - Natural person:
    - Mother name
    - Father name
  - Legal person representative:
    - Name
    - Document
    - Email
- Alias
  - Document
  - Bank account number
  - Bank account IBAN

The encryption feature uses AES-GCM with a 32-byte symmetric key and a 12-byte random nonce.

The application stores the encrypted data, prefixed with the nonce (number used once), for each field. We store the nonce along with the data because it is required for the decryption process.

You can generate the key for encryption using the following command:
```bash
openssl rand -hex 32
```

The generated key should be configured for the `LCRYPTO_ENCRYPT_SECRET_KEY` environment variable.

