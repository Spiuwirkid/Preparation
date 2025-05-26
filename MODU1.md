 Step 1 – IAM & Access Key
 Login ke AWS Console
 Masuk IAM → Users → pilih user → Security Credentials
 Create access key → pilih: “Application running outside AWS” → download CSV
 Simpan baik-baik Access Key & Secret Key – ini dipakai scoring.
 Step 2 – Buat VPC & Subnet
2.1 Buat VPC
 VPC → Your VPCs → Create VPC
Name: LKS-CC-2024-VPC
IPv4 CIDR: 10.0.0.0/16
Tag: Key=LKS-CC-2024, Value=VPC
Klik Create VPC
2.2 Buat Subnet
 VPC → Subnets → Create subnet
VPC: LKS-CC-2024-VPC
Availability Zone:
us-west-2a → Subnet 10.0.0.0/28 (PUBLIC-SUBNET-A)
us-west-2b → Subnet 10.0.0.16/28 (PUBLIC-SUBNET-B)
us-west-2a → Subnet 10.0.0.32/28 (PRIVATE-SUBNET-A)
us-west-2b → Subnet 10.0.0.48/28 (PRIVATE-SUBNET-B)
Tambahkan tag di masing-masing subnet sesuai soal.
 Step 3 – Internet Gateway & NAT Gateway
3.1 Buat Internet Gateway
 VPC → Internet Gateways → Create internet gateway
Name: INTERNET-GW
Tag: Key=LKS-CC-2024, Value=INTERNET-GW
Attach to VPC: pilih VPC LKS-CC-2024-VPC
3.2 Buat Elastic IP
 EC2 → Network & Security → Elastic IPs → Allocate Elastic IP
Klik Allocate – ini buat NAT Gateway.
3.3 Buat NAT Gateway
 VPC → NAT Gateways → Create NAT Gateway
Subnet: pilih PUBLIC-SUBNET-A
Elastic IP: pilih EIP yang sudah dialokasikan
Name: NAT-GW
Tag: Key=LKS-CC-2024, Value=NAT-GW
Klik Create NAT Gateway
 Step 4 – Route Tables
4.1 Buat Route Table
 VPC → Route Tables → Create route table
Public Route:
Name: PUBLIC-ROUTE
Tag: Key=LKS-CC-2024, Value=PUBLIC-ROUTE
Private Route:
Name: PRIVATE-ROUTE
Tag: Key=LKS-CC-2024, Value=PRIVATE-ROUTE
4.2 Tambahkan Route
Public:
Pilih PUBLIC-ROUTE → Routes → Edit routes → Add route
Destination: 0.0.0.0/0
Target: pilih Internet Gateway (INTERNET-GW)
Private:
Pilih PRIVATE-ROUTE → Routes → Edit routes → Add route
Destination: 0.0.0.0/0
Target: pilih NAT Gateway (NAT-GW)
4.3 Associate Subnet
Public:
Pilih PUBLIC-ROUTE → Subnet associations → Edit
Centang: PUBLIC-SUBNET-A & PUBLIC-SUBNET-B
Private:
Pilih PRIVATE-ROUTE → Subnet associations → Edit
Centang: PRIVATE-SUBNET-A & PRIVATE-SUBNET-B
 Step 5 – Security Group
 EC2 → Security Groups → Create security group
Name: SECURITY-GROUP
Description: LKS-CC-2024
VPC: LKS-CC-2024-VPC
Inbound Rules:
HTTP (80), Source: 0.0.0.0/0
HTTPS (443), Source: 0.0.0.0/0
Tag: Key=LKS-CC-2024, Value=SECURITY-GROUP
Klik Create
 Step 6 – Launch Template
 EC2 → Launch Templates → Create launch template
Name: LKS-CC-2024-ASG-TEMPLATE
AMI: Ubuntu 24.04 (default AWS Marketplace)
Instance type: t3a.micro
Key pair: pilih (atau buat baru)
Network: No preference
Security Group: SECURITY-GROUP
Advanced details → User data:
Copy user_data.sh dari repo:
https://github.com/itsgitz/lksccjabar2024modul1_aplikasi
Paste script ke kolom.
Tag: Key=LKS-CC-2024, Value=ASG-TEMPLATE
Klik Create launch template
 Step 7 – Application Load Balancer
 EC2 → Load Balancers → Create Load Balancer
Type: Application Load Balancer
Name: LKS-CC-2024-ELB
Scheme: Internet-facing
Subnets: PUBLIC-SUBNET-A & PUBLIC-SUBNET-B
Security Group: SECURITY-GROUP
Listener: HTTP (80) redirect ke HTTPS (443)
Target Group:
Name: LKS-CC-2024-ELB-TARGET
Protocol: HTTP
Health Check: enable
Tag: Key=LKS-CC-2024, Value=ELB-TARGET-GROUP
Tag Load Balancer: Key=LKS-CC-2024, Value=ELB
 Step 8 – ACM Certificate
 ACM → Request Certificate
Domain: *.[YOUR_DOMAIN]
Validation: email / DNS
Tag: Key=LKS-CC-2024, Value=ACM
 Step 9 – Auto Scaling Group
 EC2 → Auto Scaling Groups → Create Auto Scaling group
Name: LKS-CC-2024-ASG
Launch Template: LKS-CC-2024-ASG-TEMPLATE
VPC: LKS-CC-2024-VPC
Subnets: PRIVATE-SUBNET-A & PRIVATE-SUBNET-B
Attach ke Target Group: LKS-CC-2024-ELB-TARGET
Desired/Min/Max: 2 / 2 / 4
Scaling policy: average CPU utilization = 85%
Tag: Key=LKS-CC-2024, Value=ASG
 Step 10 – Route53 Hosted Zone
 Route 53 → Hosted Zones → Create hosted zone
Domain: [YOUR_DOMAIN]
Tag: Key=LKS-CC-2024, Value=DNS
 Buat record A / alias ke ALB DNS.
 Step 11 – Setup HTTPS Listener di ALB
 EC2 → Load Balancers → Pilih LKS-CC-2024-ELB → Listeners
Edit:
HTTP (80) → redirect ke HTTPS (443)
HTTPS (443): gunakan certificate dari ACM.
 Step 12 – SNS Notification
 SNS → Create topic
Name: LKS-CC-2024-TOPIC
Tag: Key=LKS-CC-2024, Value=SNS
 Create subscription
Protocol: Email
Endpoint: email aktif kamu
Konfirmasi email (cek inbox!)
