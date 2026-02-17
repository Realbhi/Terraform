# Terraform Import Notes (Complete)

## ✅ What is Terraform Import?

Terraform import is used to **bring an already existing AWS resource** (created manually or by someone else) into Terraform management.

It does **NOT create** the resource.

It only adds that resource into Terraform **state file**.

---

# ✅ What does import actually do?

### Terraform Import updates only:

📌 `terraform.tfstate`

### Terraform Import does NOT update:

❌ `.tf` configuration files

❌ does not auto-write AMI, instance type, tags, SG, etc.

So after import, you must manually update your `.tf` files.

---

# 🪜 Steps to Import a Resource (Correct Workflow)

## Step 1: Create resource manually in AWS

Example: Create EC2 instance from AWS console.

Now you have:

* Instance ID like `i-0abc123456`

---

## Step 2: Write a Terraform resource block (dummy is okay)

Example:

```hcl
resource "aws_instance" "imported_ec2" {
  ami           = "dummy"
  instance_type = "dummy"
}
```

Terraform just needs valid syntax.

---

## Step 3: Run terraform init

```bash
terraform init
```

---

## Step 4: Run terraform import

Format:

```bash
terraform import <resource_type.resource_name> <unique_id>
```

Example:

```bash
terraform import aws_instance.imported_ec2 i-0abc123456
```

Now Terraform state has this EC2.

---

## Step 5: Check imported resource values

Use:

```bash
terraform state show aws_instance.imported_ec2
```

This gives real values like subnet, SG, tags, etc.

---

## Step 6: Update your `.tf` file with correct values

Fill real configuration.

---

## Step 7: Run terraform plan

```bash
terraform plan
```

If Terraform shows changes like "will destroy and recreate", then your config still doesn't match AWS.

Fix config until plan becomes clean.

---

## Step 8: Run terraform apply

```bash
terraform apply
```

Now Terraform will manage the resource without duplicating it.

---

# ⚠️ Important Notes

## ✅ Import = only state mapping

Terraform import basically tells Terraform:

👉 “This AWS resource belongs to this Terraform resource name”

Example:

```bash
terraform import aws_instance.x i-123
```

means:
`aws_instance.x` is actually `i-123` in AWS.



---

# How Terraform knows what ID to use?

Every AWS resource has a **unique identifier** that AWS uses.

Terraform import requires that identifier.

Examples below 👇

---

#  Common Terraform Import IDs (AWS)

## ✅ EC2 Instance

```bash
terraform import aws_instance.myec2 i-0abcd12345
```

ID = **instance-id**

---

## ✅ Security Group

```bash
terraform import aws_security_group.mysg sg-0123456789
```

ID = **security group id**

---

## ✅ VPC

```bash
terraform import aws_vpc.main vpc-0123456
```

ID = **vpc id**

---

## ✅ Subnet

```bash
terraform import aws_subnet.public subnet-0123456
```

ID = **subnet id**

---

## ✅ Internet Gateway

```bash
terraform import aws_internet_gateway.igw igw-0123456
```

---

## ✅ Route Table

```bash
terraform import aws_route_table.rt rtb-0123456
```

---

## ✅ S3 Bucket

```bash
terraform import aws_s3_bucket.mybucket my-bucket-name
```

ID = **bucket name** (globally unique)

---

## ✅ IAM User

```bash
terraform import aws_iam_user.user user-A
```

ID = **username**

---

## ✅ Key Pair (IMPORTANT)

```bash
terraform import aws_key_pair.mykey my-key-name
```

ID = **key name**, not key-id.

So yes you are correct:

👉 `terraform import aws_key_pair.nameofresource <key-name>`

---

## ✅ Elastic IP

```bash
terraform import aws_eip.myeip eipalloc-0123456
```

---

## ✅ EBS Volume

```bash
terraform import aws_ebs_volume.vol vol-0123456
```

---

## ✅ RDS Instance

```bash
terraform import aws_db_instance.db my-db-identifier
```

ID = **DB identifier name**

---

# 🧠 How to know the correct import ID for any resource?

Best way:

### Option 1: Terraform Docs

Search:
**"Terraform aws_<resource> import"**

Example:
`terraform aws_key_pair import`

Docs will show exact import format.

### Option 2: AWS Console

Check resource unique ID like:

* vpc-id
* sg-id
* subnet-id
* instance-id

---

# ✅ Summary Notes (One Line)

### Terraform Import Steps:

**Create AWS resource → write dummy .tf → terraform import → terraform state show → update .tf → terraform plan → terraform apply**

### Terraform Import Meaning:

**Import = add existing resource into tfstate only.**


