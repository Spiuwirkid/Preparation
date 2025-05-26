Alright, let’s get this done **via the AWS Console GUI** (not CLI, SAM, CDK, etc.). I’ll walk you step-by-step based on the full instructions.

---

### **🌟 Summary of What We’ll Do:**

1️⃣ **S3 Bucket**
2️⃣ **Lambda Function**
3️⃣ **Kinesis Firehose**
4️⃣ **IoT Rule & Policy & Certificate**
5️⃣ **ACM Certificate & IoT Domain & Route53**
6️⃣ **Testing**

---

## 1️⃣ S3 Bucket

✅ **Login to AWS Console → S3**

1. **Create bucket**

   * Name: e.g. `lks-iot-data-bucket`
   * Region: **us-east-2 (Ohio)**
   * **Block all public access**
   * **Disable versioning**
   * Next → Next → Create bucket.

2. **Add Tag**

   * Go to your bucket → Properties → Tags → Add tag:

     * Key: `LKS-CC-2024`
     * Value: `LKS-IOT-S3`

---

## 2️⃣ Lambda Function

✅ **Login to Lambda → Create function**

1. **Author from scratch**

   * Name: e.g. `lks-iot-transform`
   * Runtime: `Python 3.12`
   * Architecture: `arm64`
   * Permissions: Create new role with basic Lambda permissions.

2. **Configure function**

   * Memory: `256 MB`
   * Timeout: `1 min`
   * Ephemeral storage: `512 MB`

3. **Add Tag**

   * Key: `LKS-CC-2024`
   * Value: `LKS-IOT-LAMBDA`

4. **Upload code**

   * From your repo: [https://github.com/kensasongko/lksccjabar2024modul2\_aplikasi](https://github.com/kensasongko/lksccjabar2024modul2_aplikasi)
   * Usually, you’d zip the Lambda code (`lambda_function.py`) and upload in the **Code source** section.

5. **Ensure handler is correct**

   * e.g. `lambda_function.lambda_handler` if your code file is named `lambda_function.py`.

---

## 3️⃣ Kinesis Firehose

✅ **Go to Kinesis → Delivery streams → Create**

1. **Source**

   * Direct PUT

2. **Transform**

   * Enable transform → Choose your Lambda function → Version: `$LATEST`

3. **Destination**

   * S3 bucket: the bucket you created (`lks-iot-data-bucket`)
   * Prefix: `data/`
   * Error prefix: `error/`

4. **Buffer hints**

   * Buffer size: `1 MB`
   * Buffer interval: `60 sec`
   * New line delimiter: Enabled
   * Compression: `GZIP`

5. **Time zone**

   * UTC

6. **Tags**

   * Key: `LKS-CC-2024`
   * Value: `LKS-IOT-FIREHOSE`

7. **Name**

   * e.g. `lks-iot-firehose`

---

## 4️⃣ IoT Core Rules & Policy

✅ **AWS IoT Core → Message Routing → Rules → Create**

1. **Name**

   * `ToFirehose`

2. **SQL**

   * SQL version: `2016-03-23`
   * Statement:

     ```
     SELECT * FROM 'location/#'
     ```

3. **Actions**

   * Add action → Kinesis Firehose → Choose the stream you created (`lks-iot-firehose`)
   * Separator: `\n`

4. **IAM Role**

   * Create new role: `IoTRuleToFirehoseRole`

5. **Tags**

   * Key: `LKS-CC-2024`
   * Value: `LKS-IOT-RULE`

---

✅ **AWS IoT Core → Secure → Policies → Create**

1. **Name**

   * e.g. `LKS-IOT-Policy`

2. **Policy document**

   * Allow `iot:Connect`, `iot:Publish` to `*`.

3. **Tags**

   * Key: `LKS-CC-2024`
   * Value: `LKS-IOT-POLICY`

---

✅ **Certificates**

* **Create → Create certificate** → Auto-generate
* **Download keys** (private key, cert, Amazon Root CA)
* **Attach policy** → Attach the IoT policy you created (`LKS-IOT-POLICY`)

---

## 5️⃣ ACM Certificate, IoT Domain, and Route 53

✅ **ACM → Request a certificate**

* **Request public certificate** → Enter `lks-iot.[YOUR_DOMAIN]`
* Validation: Email/DNS (use your domain provider to update DNS if needed)

✅ **IoT Core → Settings → Custom domains → Create domain configuration**

* Name: `lks-iot`
* Domain type: `Customer managed domain`
* Domain name: `lks-iot.[YOUR_DOMAIN]`
* Server certificate: choose the ACM cert you created.

✅ **Route 53**

* In your hosted zone, create an **A record (or CNAME)**:

  * Name: `lks-iot.[YOUR_DOMAIN]`
  * Value: **IoT data endpoint** (copy from IoT Core → Settings → Endpoint)

---

## 6️⃣ Testing

Use your downloaded IoT certificate files with the command:

```bash
mosquitto_pub -h lks-iot.[YOUR_DOMAIN] -p 8883 \
--key /path/to/private.pem.key \
--cert /path/to/certificate.pem.crt \
--cafile /path/to/AmazonRootCA1.pem \
-t location/device1 -m '{"hello": "test"}' -id1 -d
```

---

## 7️⃣ Verify in S3

* Go to your bucket → Check for files in `data/` prefix.
* Check if the payloads include `"processedAt": "<timestamp>"`.

---

Would you like me to create a checklist file you can download, or are there particular **screenshots or JSON policy** you’d like me to generate for you? Let me know! 🚀
