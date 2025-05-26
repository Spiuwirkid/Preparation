Baik! Ini dia tutorial lengkap dan step-by-step dari Modul 3 Lomba LKS Bidang *Cloud Computing* Jawa Barat 2024.

---

## 🟩 **PERSIAPAN**

✅ Pastikan sudah punya:

* AWS Account.
* IAM user dengan akses penuh ke:

  * DynamoDB.
  * Lambda.
  * API Gateway.
  * S3.
  * CloudFront.
* AWS CLI (opsional, bisa pakai AWS Console saja).
* File ZIP Lambda (connect-handler.zip, disconnect-handler.zip, sendmessage-handler.zip, default-handler.zip).
* File ZIP website (web.zip).

✅ Semua resource **WAJIB dibuat di region: `ap-southeast-1`** (Singapura).

---

## 🟩 **LANGKAH-LANGKAH**

### 1️⃣ **Buat DynamoDB Table**

1. Masuk ke AWS Console → DynamoDB → Create Table.
2. Isi:

   * **Table name**: `lks-jabar-2024-connection`.
   * **Partition key**:

     * Name: `connectionId`
     * Type: `String`.
   * **Sort Key**: Biarkan kosong.
3. Klik **Customize Settings**.
4. **Table class**: DynamoDB Standard.
5. **Capacity mode**: On-demand.
6. **Tag**:

   * Key: `LKS-CC-2024`
   * Value: `lks-chat-table`.
7. Klik **Create Table**.

---

### 2️⃣ **Buat Lambda Functions**

#### 🟦 A. Connect Handler

1. Masuk ke **Lambda Console** → Create function → Author from scratch.
2. Isi:

   * Function name: `api-ws-connect-handler`.
   * Runtime: `Node.js 16.x`.
   * Architecture: `x86_64`.
3. Tambahkan tag:

   * Key: `LKS-CC-2024`
   * Value: `lks-chat-connect-handler`.
4. Tambahkan environment variable:

   * Key: `table`
   * Value: `lks-jabar-2024-connection`.
5. Upload `connect-handler.zip` (di tab Code → Upload from → .zip file).
6. Buka tab **Configuration → Permissions → Execution role** → Klik nama role.
7. Di **IAM Role**, pilih **Add permissions → Create inline policy**.

   * Gunakan JSON berikut:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:DescribeTable",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-southeast-1:<account-id>:table/lks-jabar-2024-connection"
    }
  ]
}
```

* Ganti `<account-id>` dengan AWS Account ID-mu.
* Save as: `api-ws-connect-handler-db-policy`.

---

#### 🟦 B. Disconnect Handler

1. Sama seperti Connect Handler, bedanya:

   * Function name: `api-ws-disconnect-handler`.
   * Tag:

     * Key: `LKS-CC-2024`
     * Value: `lks-chat-disconnect-handler`.
   * Upload file: `disconnect-handler.zip`.
2. Buat inline policy di role dengan JSON yang sama seperti Connect Handler (disesuaikan resource ARN).

   * Save as: `api-ws-disconnect-handler-db-policy`.

---

#### 🟦 C. SendMessage Handler

1. Sama seperti di atas:

   * Function name: `api-ws-sendmessage-handler`.
   * Tag:

     * Key: `LKS-CC-2024`
     * Value: `lks-chat-sendmessage-handler`.
   * Upload file: `sendmessage-handler.zip`.
2. Buat policy dengan JSON berikut:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:Query",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:ConditionCheckItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:ap-southeast-1:<account-id>:table/lks-jabar-2024-connection"
    },
    {
      "Sid": "Statement2",
      "Effect": "Allow",
      "Action": "execute-api:ManageConnections",
      "Resource": "arn:aws:execute-api:ap-southeast-1:<account-id>:*/*/POST/@connections/*"
    }
  ]
}
```

* Save as: `api-ws-sendmessage-handler-db-policy`.

---

#### 🟦 D. Default Handler

1. Sama seperti di atas:

   * Function name: `api-ws-default-handler`.
   * Tag:

     * Key: `LKS-CC-2024`
     * Value: `lks-chat-default-handler`.
   * Upload file: `default-handler.zip`.
2. Buat policy dengan JSON berikut:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Action": "execute-api:ManageConnections",
      "Resource": "arn:aws:execute-api:ap-southeast-1:<account-id>:*/*/POST/@connections/*"
    },
    {
      "Sid": "Statement2",
      "Effect": "Allow",
      "Action": "execute-api:ManageConnections",
      "Resource": "arn:aws:execute-api:ap-southeast-1:<account-id>:*/*/GET/@connections/*"
    }
  ]
}
```

* Save as: `api-ws-default-handler-db-policy`.

---

### 3️⃣ **Buat WebSocket API di API Gateway**

1. Masuk ke **API Gateway Console** → Create API → WebSocket.
2. API name: `ws-chat-app`.
3. Route selection expression: `request.body.action`.
4. Tambahkan routes:

   * Predefined: `$connect`, `$disconnect`, `$default`.
   * Custom route: `sendmessage`.
5. Integrasikan masing-masing route ke Lambda:

   * \$connect: `api-ws-connect-handler`.
   * \$disconnect: `api-ws-disconnect-handler`.
   * \$default: `api-ws-default-handler`.
   * sendmessage: `api-ws-sendmessage-handler`.
6. Deploy API:

   * Stage name: `production`.
7. Tambahkan tag:

   * Key: `LKS-CC-2024`
   * Value: `lks-chat-websocket-api`.

---

### 4️⃣ **Buat S3 Website Hosting**

#### 🟦 A. Buat S3 Bucket

1. Nama bucket: `ws-chat-web-<account_id>`.
2. Object ownership: ACLs enabled (Bucket owner preferred).
3. Block public access: Nonaktifkan.
4. Tag:

   * Key: `LKS-CC-2024`
   * Value: `lks-chat-ws-chat-bucket`.
5. Static website hosting:

   * Enable.
   * Index document: `index.html`.

---

#### 🟦 B. Upload Website

1. Ekstrak `web.zip` di laptop.
2. Upload file HTML, CSS, JS, dsb. ke bucket (tab Objects).
3. Set permissions → ACL → Grant public read access.

---

#### 🟦 C. Test

* Buka tab **Properties** → **Static website hosting** → Copy URL dan buka di browser.

---

### 5️⃣ **Buat CloudFront Distribution**

1. Masuk ke **CloudFront Console** → Create Distribution.
2. Origin domain: domain dari URL S3 website (tanpa https\://).
3. HTTP port: 80.
4. Name: `ws-chat-distribution`.
5. Default cache behavior:

   * Viewer protocol policy: Redirect HTTP to HTTPS.
6. Alternate domain name: `chat.<your_domain>`.
7. Tambahkan tag:

   * Key: `LKS-CC-2024`
   * Value: `lks-chat-ws-chat-distribution`.

---

### 6️⃣ **Buat DNS Record**

* Di DNS provider (misalnya Route53 / Cloudflare), buat **CNAME**:

  * Name: `chat.<your_domain>`
  * Value: domain CloudFront.

---

### 7️⃣ **Uji Chat**

1. Buka `chat.<your_domain>` di 2+ tab browser.
2. Coba kirim pesan dan lihat interaksi **real-time**! 🎉

---

### 📌 **Tips Tambahan**

✅ Pastikan Lambda role punya permission ke DynamoDB dan `execute-api:ManageConnections` (ARNnya benar).
✅ Tes tiap step → perbaiki error sebelum lanjut.
✅ Gunakan **ap-southeast-1** untuk semua resource!

---

Mau aku bantu bikin policy ARN otomatis (misal Account ID kamu: `123456789012`)? Atau mau aku bantu rangkum dalam format PDF? 🚀✨
