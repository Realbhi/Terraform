

# ✅ Goal

We want:

* Terraform state stored in **S3** (remote backend)
* Terraform locking handled by **DynamoDB**
* Team-safe workflow (no state conflict)

---

#  STEP 1: Create S3 + DynamoDB in a separate folder (Backend folder)

### 📂 Folder structure

```
terraform-project/
   backend/
   main-infra/
```

---

## ✅ Why create backend in a different folder?

Because **backend resources must exist BEFORE Terraform can use them**.

If you create S3 bucket + DynamoDB inside the same project:

* Terraform needs S3 backend to store state
* But bucket doesn’t exist yet
* Circular dependency problem

### MAIN REASON 

If your backend (S3 + DynamoDB) is created inside the same Terraform project as your main infra, then:

If you run: terraform destroy

Terraform will destroy EVERYTHING, including:

❌ S3 bucket (where your state is stored)
❌ DynamoDB table (locking)

And if the bucket is deleted → your terraform.tfstate is gone → disaster.

---

## Backend folder files example

### `provider.tf`

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

### `s3.tf`

```hcl
resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = "kalaburagi-bucket"
}
```

### `dynamodb.tf`

```hcl
resource "aws_dynamodb_table" "tf_lock_table" {
  name         = "Remote-backend-dynamo-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

---

## Run these commands

```bash
terraform init
terraform apply
```

---

## ⚠️ Error you might face here

### ❌ "BucketAlreadyExists"

Because S3 bucket name is globally unique.

✅ Fix: choose a unique name like:
`kalaburagi-bucket-ash-2026`

---

## ⚠️ DynamoDB error possibility

If you accidentally wrote:

```hcl
hash_key = "LOCKID"
```

and attribute is:

```hcl
name = "LockID"
```

Terraform will error because key names must match exactly.

✅ Fix:
Use exact **LockID** everywhere.

---

#  STEP 2: Configure backend in Main Infra folder

Now go to folder:

```
main-infra/
```

In this folder you have your infra code (VPC, EC2, SG, etc).

---

## Create `terraform.tf` backend block

```hcl
terraform {
  backend "s3" {
    bucket         = "kalaburagi-bucket"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "Remote-backend-dynamo-db"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.32.1"
    }
  }
}
```

---

## Run init

```bash
terraform init -reconfigure
```

(or if state already exists locally and you want to move it)

```bash
terraform init -migrate-state
```

---

##  Common error you faced here:

You said:

> terraform apply is not acquiring lock even after terraform init

That happens when:

### Cause 1: Backend config was added after init

Terraform was still using old backend.

✅ Fix:

```bash
terraform init -reconfigure
```

---

### Cause 2: DynamoDB table partition key wrong

Terraform locking works only if DynamoDB has key:

✅ **LockID** (exact spelling)

Your table was correct:

```hcl
hash_key = "LockID"
```

So backend should lock correctly.

---

#  STEP 3: Delete local terraform.tfstate? (IMPORTANT CLARIFICATION)

You wrote:

> then delete tfstate from folder one because not needed anymore

### ✅ Truth:

After successful backend init + migration,
Terraform will no longer use local `terraform.tfstate`.

But I recommend:

### Best practice:

✅ Do NOT manually delete state file before migration
Only delete it after confirming everything is stored in S3.

---

## How to confirm backend is active?

Run:

```bash
terraform state list
```

If it shows resources, Terraform is reading state from backend.

Also check S3 bucket → you will see file:

`terraform.tfstate`

---

#  STEP 4: Terraform now uses S3 as state storage

Now your workflow becomes safe:

* Terraform reads state from S3
* Terraform writes state back to S3
* Everyone shares one state file

So now if Person1 and Person2 run terraform, both see the same truth.

---

#  STEP 5: DynamoDB Locking prevents simultaneous apply

This is the most important teamwork feature.

### When you run:

```bash
terraform apply
```

Terraform creates a lock record in DynamoDB table:

| LockID             | Info   |
| ------------------ | ------ |
| terraform-lock-xyz | locked |

Now if another person tries apply:

❌ they will get:

> Error acquiring the state lock

This prevents state corruption.

---

## How to confirm locking works?

While apply is running and before confirming by typing yes :

* Go to DynamoDB table
* Explore items
* You should see LockID entry

After apply finishes, entry disappears.

---

#  Errors related to locking

##  "Error acquiring the state lock"

This happens if:

* someone else is applying
* your previous apply crashed and lock remained

✅ Fix (dangerous but sometimes needed):

```bash
terraform force-unlock LOCK_ID
```

(terraform will show LOCK_ID in error output)

---

#  STEP 6: Why this prevents state conflict?

Without remote backend:

* Person1 has local state
* Person2 has local state
* both think different infra exists

Result:

* duplicates
* accidental destroy/recreate

With S3 backend:

* single state shared
* no mismatch

With DynamoDB:

* only one apply at a time

---

# ✅ Correct Final Workflow Summary (Clean Notes)

### Backend folder (one-time setup)

1. create S3 bucket + DynamoDB table
2. terraform init
3. terraform apply
4. never destroy casually

### Main infra folder

1. write backend block
2. terraform init -migrate-state (or -reconfigure)
3. terraform plan
4. terraform apply

Now:

* state stored in S3
* locking in DynamoDB
* team safe

---

# 🔥 Is anything missing?

YES — one more important best practice:

## ✅ Enable S3 versioning (highly recommended)

Because if state gets corrupted or overwritten, you can restore older versions.

Add this in backend folder:

```hcl
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

---

# ✅ Also recommended: Block public access

```hcl
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

