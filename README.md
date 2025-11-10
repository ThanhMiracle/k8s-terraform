# 🧩 Terraform Notes — Ghi chép & Quy ước cá nhân

Tài liệu này tổng hợp những điều cần nhớ khi làm việc với Terraform, đặc biệt khi triển khai hạ tầng Azure VM (Ubuntu + Docker + Ansible + K8s). Mục tiêu là giúp triển khai nhất quán, dễ debug và tránh các lỗi phổ biến.

## ⚙️ Cấu trúc thư mục chuẩn

```bash
terraform/
├── main.tf                # Định nghĩa resource chính
├── variables.tf           # Khai báo biến đầu vào
├── outputs.tf             # Các giá trị xuất ra (IP, SSH command, v.v.)
├── terraform.tfvars       # (tuỳ chọn) Lưu giá trị thật của biến
├── cloud-init.yaml.tftpl  # (nếu dùng cloud-init)
└── README.md              # Ghi chú & hướng dẫn
```

## 🔑 Nguyên tắc SSH Key

`ssh_public_key` trong Terraform là public key của máy cá nhân (ví dụ: `~/.ssh/id_rsa.pub`). Khi VM được tạo, key này được chèn vào `/home/<admin_user>/.ssh/authorized_keys`. Do đó, bạn SSH vào tất cả VM bằng private key tương ứng của máy cá nhân (`~/.ssh/id_rsa`). Không cần `.pem` riêng cho từng VM như AWS.

Ví dụ file Ansible inventory:

```bash
[master]
master ansible_host=20.205.1.66 ansible_user=thanh ansible_ssh_private_key_file=~/.ssh/id_rsa

[workers]
worker1 ansible_host=168.63.149.79 ansible_user=thanh ansible_ssh_private_key_file=~/.ssh/id_rsa
worker2 ansible_host=13.88.217.45 ansible_user=thanh ansible_ssh_private_key_file=~/.ssh/id_rsa

[k8s:children]
master
workers
```

## 🧱 Quy trình cơ bản

Để triển khai hạ tầng bằng Terraform, bạn thực hiện theo các bước sau:

**Khởi tạo:**
```bash
terraform init -upgrade
```

**Kiểm tra trước khi chạy:**
```bash
terraform plan -var="subscription_id=<SUB_ID>" -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

**Áp dụng thay đổi (Deploy):**
```bash
terraform apply -auto-approve -var="subscription_id=<SUB_ID>" -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

**Gỡ hạ tầng (Destroy):**
```bash
terraform destroy -auto-approve -var="subscription_id=<SUB_ID>" -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

## 🌍 Những biến quan trọng

```bash
subscription_id: Azure Subscription ID (bắt buộc)
prefix: Tiền tố đặt tên tài nguyên (ví dụ: docker-vm)
location: Vùng triển khai (East Asia, Southeast Asia, East US)
admin_username: User login SSH (ví dụ: thanh, azureuser)
ssh_public_key: Public key cá nhân (~/.ssh/id_rsa.pub)
vm_size: Cấu hình máy (ví dụ: Standard_D2s_v3)
vm_names: Danh sách VM (ví dụ: ["master", "worker1", "worker2"])
```

## 🧩 Một số lỗi hay gặp & cách xử lý

**Lỗi “context canceled” hoặc “HTTP response was nil; connection reset”**  
Nguyên nhân: mạng, proxy, VPN, TLS inspection.

```bash
export ARM_HTTP_TIMEOUT=600
terraform apply -parallelism=1
export GODEBUG=http2client=0
```

**Không xóa được Resource Group**  
Nguyên nhân: tài nguyên bị kẹt, soft-delete hoặc còn lock.

```bash
az lock delete --ids $(az lock list -g <rg> --query "[].id" -o tsv)
az resource list -g <rg> -o table
az group delete -n <rg> --yes --force-deletion-types Microsoft.Compute/disks
```

**SSH không vào được**  
Nguyên nhân: sai user hoặc key.

```bash
ssh -i ~/.ssh/id_rsa thanh@<vm_public_ip>
```

Nếu vẫn không được, kiểm tra lại `admin_username` trong Terraform.

## 🧰 Kinh nghiệm thực tế

```bash
# Dùng phiên bản Terraform và provider mới nhất
Terraform >= 1.5
azurerm >= 4.40.0

# Khi test nhiều lần, giảm song song để ổn định
terraform apply -parallelism=1

# Thêm skip_provider_registration để tránh treo khi đăng ký provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Ghi chú IP, VM name, user vào ansible/inventory.ini
# Nếu lỗi mạng, thử tắt VPN hoặc thêm management.azure.com vào NO_PROXY
```

## 📜 Lệnh hữu ích

```bash
terraform show              # Xem trạng thái tài nguyên
terraform state list        # Liệt kê resource trong state
terraform state rm <addr>   # Gỡ resource khỏi state
terraform refresh           # Đồng bộ lại state với Azure
az resource list -g <rg> -o table   # Kiểm tra tài nguyên còn lại
az group delete -n <rg> --yes       # Xóa Resource Group
```

## 🧾 Ghi chú thêm

```bash
# Luôn lưu terraform.tfstate cẩn thận (hoặc dùng backend như Azure Storage / S3)
# Dùng naming convention rõ ràng để tránh trùng tài nguyên
# Ví dụ: docker-vm-master, docker-vm-worker1, docker-vm-worker2
# Khi deploy nhiều môi trường (dev, staging, prod), tạo thư mục riêng cho mỗi môi trường
# Sau mỗi thay đổi lớn, commit lại state và ghi chú rõ trong Git
```


💡 *“Mọi thay đổi hạ tầng đều nên được kiểm soát bằng Terraform.”*
