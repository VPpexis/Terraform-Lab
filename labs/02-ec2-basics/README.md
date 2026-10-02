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
2. In the plan, why are `id`, `private_ip`, and `public_ip` `(known after apply)` instead of computed during plan?
3. You had to add a new endpoint to the provider. Why does Floci/Terraform need one per service instead of a single global endpoint? (Hint: check the `endpoints` block docs.)
4. After `apply`, what does `docker ps` show? What does that tell you about how Floci emulates EC2?
5. If you change `instance_type` and re-apply, does Terraform destroy and recreate the instance, or update in place? Try it and read the plan symbols.

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
