
#  What is State Conflict?

**State conflict happens when two people are working on the same Terraform project (managing same aws infra ) but they are using different state files.**

Terraform state (`terraform.tfstate`) is Terraform’s memory.

If the memory differs for each person → Terraform makes wrong decisions.

---

## Example (Realistic)

### Suppose your Terraform code is:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-xyz"
  instance_type = "t2.micro"
  count         = 2
}
```

---

#  Person 1 (Ash) runs terraform apply

Terraform creates:

* web[0]
* web[1]

and his local state file stores:

"I created 2 instances"

State file (person1):

```
aws_instance.web[0]
aws_instance.web[1]
```

---

#  Person 2 changes count to 3

```hcl
count = 3
```

Then Person2 runs `terraform apply`

Terraform creates:

* web[2] (new instance)

Now person2 state says:

"I created 3 instances"

State file (person2):

```
aws_instance.web[0]
aws_instance.web[1]
aws_instance.web[2]
```

---

# ⚠️ Now Person 1 runs terraform apply again

But Person 1’s state file still says: only 2 instances exist.

So Terraform thinks:

👉 "I need to create 1 more instance"

So it creates another instance again. Now AWS has **4 EC2 instances Even though Terraform code says only 3.

---

#  That is state conflict

Because both people had different state files, Terraform got confused and created extra resources.

---

#  Another dangerous case (Deletion conflict)

Person2 sets:

```hcl
count = 1
```

Person2 apply → deletes web[1] and web[2]

Now AWS has only 1 instance.

---

Now Person1 still has state saying 2 instances exist.
Person1 runs apply:

Terraform thinks:
👉 "web[1] exists, but AWS doesn't show it"
So it might recreate it.

Now deleted instance comes back 

---

#  Why remote backend fixes it

If both people use same state stored in S3:

* Person1 apply updates shared state
* Person2 reads same updated state
* No mismatch
* No duplication
* No accidental recreation

---

# 🔒 Why locking is needed

If Person1 is running apply and Person2 runs apply at same time:

Both may update the same state file simultaneously → corruption.

So DynamoDB lock ensures:

* only 1 person modifies state at a time

---

