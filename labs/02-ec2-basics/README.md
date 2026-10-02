# Lab 02 — EC2 Basics

**Goal:** Launch a single EC2 instance with Terraform against Floci, verify it is running, then destroy it.

**What you will learn:** a second resource type, provider endpoints per service, AWS defaults (VPC/subnet), and values that are only known after apply.

> Floci runs EC2 instances as **real Docker containers**, so make sure Docker is running. The first apply may take a moment while the AMI's Docker image is pulled.

---

## Prerequisites

- [ ] Floci running (`floci start`)
- [ ] Docker running (`docker info`)
- [ ] Lab 01 completed (`labs/01-s3-basics`)
- [ ] Read the [Floci EC2 guide](https://floci.io/floci/services/ec2/)

---

## Mission Checklist

- [ ] **1. Write `provider.tf`** in this folder — reuse your Lab 01 provider setup, but think: which **endpoint** must be added for EC2?
  - hint: Floci requires an endpoint entry for every AWS service used
  - reference: [Floci Terraform guide](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md)
- [ ] **2. Write `main.tf`** in this folder with one `aws_instance`:
  - `ami` — use an AMI from the [Floci EC2 catalog](https://floci.io/floci/services/ec2/) (e.g. `ami-0abcdef1234567890` = Amazon Linux 2). Unrecognized AMI IDs fall back to a default image.
  - `instance_type` — something small (`t2.micro` or `t3.micro`)
  - `tags` — give it a `Name`
  - reference: [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [ ] **3. Run the loop:**
  - `terraform init`
  - `terraform validate`
  - `terraform plan` — notice how many attributes are `(known after apply)`
  - `terraform apply`
- [ ] **4. Verify from two angles:**
  - Terraform side: `terraform state show aws_instance.<name>`
  - AWS side: `aws ec2 describe-instances --endpoint-url http://localhost:4566` (or via `floci env` + plain `aws`)
  - bonus: `docker ps` — you should see a container standing in for your instance
- [ ] **5. Clean up:** `terraform destroy` and verify the instance is gone

---

## Guiding Questions

1. Why does `aws_instance` work without `subnet_id`, `vpc_security_group_ids`, or a VPC of your own? (Hint: Floci seeds a default VPC — does real AWS do that too?)
   > In all region of AWS, they provide a deafult VPC and a default subet per AZ, an internet gateway, and a default security group, and a main route table. So like it automatically assign it to by deafult. Floci just imitate how AWS Implmeent it
2. In the plan, why are `id`, `private_ip`, and `public_ip` `(known after apply)` instead of computed during plan?
   > Since the plan only do not create the VPC and Subnet and the instance. It are only generated during creation time in AWS, subnet allocates the IP. So like if it is not created in AWS it will never have one. 
3. You had to add a new endpoint to the provider. Why does Floci/Terraform need one per service instead of a single global endpoint? (Hint: check the `endpoints` block docs.)
   > Every AWS service has like endpoints (ie. S3: `s3.us-east-1.amazon.com`, ec2: `ec2.us-east-1.amazonaws.com`). That is design so Floci adjust it based on the design, but instead of having multiple endpoints it uses one locolhost port that is why we have to map each service to it. 
4. After `apply`, what does `docker ps` show? What does that tell you about how Floci emulates EC2?
   > It create the instance that I created through terraform. Since I am using Floci it uses local instance through container, in real AWS it will create an EC2 instance on the cloud.
5. If you change `instance_type` and re-apply, does Terraform destroy and recreate the instance, or update in place? Try it and read the plan symbols.
   > When i tried to change the instace_type and do a plan. It only updates the instance_type of my instance. So from t2.micro -> t3.micro all of the other properties still remain unchange.

---

## Stretch Goals (optional, after the checklist)

- Move `instance_type` and the `Name` tag into **input variables** (`variables.tf`) with defaults.
- Add an **output** for the instance `id` and `public_ip` so you can read them with `terraform output`.
- Look up the AMI dynamically with the [aws_ami data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) instead of hardcoding it.

---

## Docs

- [Floci — EC2](https://floci.io/floci/services/ec2/)
- [Floci — Terraform with Floci](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md)
- [aws_instance resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [AWS provider — custom service endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/custom-service-endpoints)

---

## Rules of the Lab

- **You write all `.tf` code.** AI explains, reviews, and hints — it does not author configurations.
- Never commit state files (already covered by the root `.gitignore`).
- Never point Terraform at real AWS — Floci only.
- Run `terraform fmt` before committing.

## Learnings

### Understanding the basics of EC2

**AWS EC2** is Amazon's service for deploying virtual machines (servers) in their infrastructure. Users can pick from assorted AMIs created by you, Amazon, or a third party.

### What is AMI?

**AMI** (full name: **Amazon Machine Image**) is a template for what OS your virtual machine will deploy — for example Linux, Windows Server, or any other OS. Not only that, it can be configured further: a web server AMI could be Linux + Nginx, a database AMI could be Linux + PostgreSQL, something like that.

### Important commands

`grep`: lets you search console output quickly. When searching through images/AMIs, run `aws ec2 describe-images` to get a list of AMIs, combine it with `> output.json` to save the output to a file, then use `grep` to filter through the different AMIs easily.

`aws sts get-caller-identity`: crucial for me (using Floci cuz I'm broke AF), but in production it's useful to confirm which AWS account/identity the CLI is connected as.

`aws ec2 describe-images`: lists the AMIs available.

`aws ec2 describe-instances`: lists EC2 instances.

### terraform state (list / show)

After `apply`, `terraform state list` showed:
```
data.aws_ami.alpine
aws_instance.example
```

Interesting: the **data source appears too** — its lookup result is cached in state, alongside the real resource.

`terraform state show aws_instance.example` printed what Terraform recorded, e.g.:
- `id = "i-647cd3e5b041ca409"` — the real instance ID
- `instance_state = "running"`
- `private_ip = "172.31.32.10"`
- `subnet_id = "subnet-default-us-east-1-c"` — the default subnet, no VPC code written!
- `security_groups = ["default"]`

**When do I actually use these commands?**
- **Verify what Terraform believes exists** — compare `state show` against `aws ec2 describe-instances`. If they disagree, reality changed outside Terraform (drift).
- **Find resource addresses** — `state list` when I forget a resource's local name; needed for `-target`, `state show`, `import`, etc.
- **Inspect without reading raw state** — `terraform.tfstate` is JSON, but `state show` formats it for humans.
- `list` and `show` are **read-only** — safe to spam anytime.

Advanced (rare, they **mutate state** — danger zone, but good to know they exist):
- `terraform import <addr> <id>` — bring an existing resource under Terraform management.
- `terraform state rm <addr>` — stop tracking a resource *without* deleting it.
- `terraform state mv <old> <new>` — rename/move a resource in state when refactoring, avoiding destroy + recreate.

Rule: never hand-edit `terraform.tfstate`. Use these commands instead.