# Lab 01 — S3 Basics

**Goal:** Provision a single S3 bucket with Terraform against Floci, verify it exists, then destroy it.

**What you will learn:** the core Terraform loop — `init` → `validate` → `plan` → `apply` → `destroy` — plus providers, resources, and state.

---

## Prerequisites

- [ ] Terraform installed (`terraform version`)
- [ ] Floci running (`floci start`)
- [ ] Read the [Floci Terraform guide](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md)

---

## Mission Checklist

- [x] **1. Write `main.tf`** in this folder (you write it, AI reviews it)
- [x] **2. Provider block** — configure the `aws` provider to talk to Floci:
  - region (any region works)
  - dummy credentials (`test` / `test` is the documented convention)
  - an `endpoints` entry mapping **s3** to `http://localhost:4566`
  - the [Floci Terraform guide](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md) shows the exact arguments required
- [x] **3. Resource block** — one `aws_s3_bucket` with a `bucket` name of your choice
  - reference: [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [x] **4. Run the loop:**
  - `terraform init`
  - `terraform validate`
  - `terraform plan` — read the output before applying
  - `terraform apply`
- [x] **5. Verify the bucket exists** — pick one:
  - `aws s3 ls --endpoint-url http://localhost:4566`
  - `terraform state list`
- [x] **6. Clean up:** `terraform destroy` and verify the bucket is gone

---

## Guiding Questions

Answer these as you go — they are the real point of this lab:

1. What does `terraform init` actually download, and why is it needed before `plan`?
2. Why does `plan` show `1 to add` instead of just creating the bucket immediately?
3. What file appeared in this folder after `apply`, and what is its purpose?
4. Why must the bucket name be globally unique in real AWS? (Floci is lenient, but build the habit.)
5. What happens to the bucket if you delete the `main.tf` without running `destroy`?

---

## Docs

- [Floci — Terraform with Floci](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md)
- [AWS provider — custom service endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/custom-service-endpoints)
- [aws_s3_bucket resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Terraform — The Core Workflow](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build)

---

## Rules of the Lab

- **You write all `.tf` code.** AI explains, reviews, and hints — it does not author configurations.
- Never commit state files (already covered by the root `.gitignore`).
- Never point Terraform at real AWS — Floci only.
- Run `terraform fmt` before committing — aesthetics are aura.

---

## Learnings

### terraform init

`terraform init` is the setup step that turns the directory into a Terraform project.
  - Reads the `.tf` files and checks which provider is required (`hashicorp/aws`).
  - Downloads provider plugins into `.terraform/`
  - Configures the backend (local by default; the state file `terraform.tfstate` is written after `apply`)
  - Writes `.terraform.lock.hcl`

`.terraform/` is gitignored, but `.terraform.lock.hcl` should be committed so provider versions stay locked.

**Why it must run first before `plan`?**

`plan` needs the provider plugins present to build the resource graph, so the dependencies must be fetched first.

Reference: [Terraform init docs](https://developer.hashicorp.com/terraform/cli/commands/init)

### terraform plan

`terraform plan` is the dry run — it shows what would happen without making any changes.

1. **Refresh** - reads your state file, then asks the provider what actually exists right now. State can drift from reality.
2. **Diff** - compares the following:
   - Desired: what your `.tf` code says
   - Current: what state + reality show
   - Result: the difference between them
3. **Output** - the execution plan, with symbols:
   - `+` create
   - `~` update in place
   - `-/+` destroy and recreate (same resource, new identity)
   - `-` destroy

Sample Output:
```console
$ 01-s3-basics % terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions
are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.example will be created
  + resource "aws_s3_bucket" "example" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "unique=123"
      + bucket_domain_name          = (known after apply)
      + bucket_namespace            = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = "us-east-1"
      + request_payer               = (known after apply)
      + tags_all                    = (known after apply)
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + cors_rule (known after apply)

      + grant (known after apply)

      + lifecycle_rule (known after apply)

      + logging (known after apply)

      + object_lock_configuration (known after apply)

      + replication_configuration (known after apply)

      + server_side_encryption_configuration (known after apply)

      + versioning (known after apply)

      + website (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take
exactly these actions if you run "terraform apply" now.
```

> Heads up: `bucket = "unique=123"` is invalid in real AWS — bucket names allow only lowercase letters, numbers, hyphens, and dots (3–63 characters). Floci and `terraform validate` may not catch it, but real AWS rejects it at apply. Fix it before running `apply`.

Now when I ran `terraform plan`, it showed the output above. Important: plan didn't create anything — it only predicted what `apply` would do. Still, this level of abstraction is amazing!! Instead of going through multiple hoops of configuration, 3 lines of code described the entire bucket. However, I must be careful since it's highly abstracted: most of the setup is hidden, so fine-tuning specific specs might be tricky.

I also noticed the usage of the `-out` flag option — this is new to me. It saves the reviewed plan into a file, then applies that *exact plan*.

```
terraform plan -out=tfplan    # review it
terraform apply tfplan        # execute exactly what was reviewed
```

#### Why it matters?
Instead of `terraform apply` running a fresh plan, it executes exactly the plan created during `terraform plan`. 

#### Scenario on doing tf plan

Example when you are in a team and making changes to the infrastructure. You run `terraform plan` and it shows this output:

```
Plan: 0 to add, 1 to change, 0 to destroy
```

While you go out or take a poopie, someone from your team makes a tweak to a resource.

Then you run `terraform apply`. It re-plans first, shows this new output, and waits for your confirmation before doing anything:

```
Plan: 1 to add, 1 to change, 1 to destroy
```

CONGRATS BRO! You are now going to be fired. Just kidding — but two corrections here. First, plain `terraform apply` re-plans **and shows you the new plan with a confirmation prompt**, so you would see the changed blast radius before typing `yes`. The real danger is automation (`-auto-approve`) or blindly smashing `yes`. Second, Terraform itself **is idempotent** — applying the same config twice makes the second apply a no-op. What's *not* guaranteed is that two plans produce the same actions, because each plan is a **snapshot** computed against the infrastructure's current state, and that can move. With `-out`, we use `terraform apply tfplan`, which either does exactly what was approved during the **planning stage**, or errors with "saved plan is stale" if reality moved. 

Key properties:
- It does not change infrastructure — but it does refresh, and it can update the state file, in order to detect drift. 

Reference: [Terraform Plan Docs](https://developer.hashicorp.com/terraform/cli/commands/plan)

### terraform fmt

`terraform fmt` is the auto-formatter - it rewrites your `.tf` files into Terraform's canonical style. Think Prettier, but for HCL.

#### What it actually does:
- **Indentation**: 2 spaces per level.
- **Alignment**: Lines up consecutive `=` signs so blocks scan cleanly (`source =` / `version =`)
- **Spacing**: consistent spacing around operators, blocks, and arguments.
- One trailing newline at end of file

#### Key properties:
- It only touches formatting, never meaning - same plan before and after.
- It rewrites files in place (that's the point - unlike `-check`)
- Options you'll actually use:
  - `terraform fmt -check` - no writes; exit code 3 if anything's unformatted (perfect for CI/pre-commit)
  - `terraform fmt -diff` - show the changes without applying
  - `terraform fmt -recursive` - format every subfolder

Reference: [terraform fmt](https://developer.hashicorp.com/terraform/cli/commands/fmt)

### terraform state

The state file (`terraform.tfstate`) is Terraform's memory. It records every resource Terraform created and maps it from my config to the real thing. After `apply`, `terraform.tfstate` appeared in the lab folder.

When I ran:
```bash
terraform state list
```
it showed:
```
aws_s3_bucket.example
```

That is the **resource address** — `type.local_name`:
- `aws_s3_bucket` is the resource **type**
- `example` is the **local name** I gave it (the second label in `resource "aws_s3_bucket" "example"`)

It is NOT the actual bucket name. If I renamed the bucket, the address would still be `aws_s3_bucket.example`.

To inspect the real attributes:
```bash
terraform state show aws_s3_bucket.example
```
shows the tracked values, e.g. `arn = "arn:aws:s3:::unique123"`, `bucket = "unique123"`, and many more.

Key properties:
- State is how Terraform knows what already exists. Without it, Terraform would try to create the bucket again on every apply.
- It is the mapping: **config address ↔ real resource attributes**.
- `plan`'s refresh step compares state against reality to detect drift (manual changes made outside Terraform).
- Never edit `terraform.tfstate` by hand — use the `terraform state` subcommands (`list`, `show`, `mv`, `rm`).
- Never commit it — state can contain secrets in plaintext. The root `.gitignore` already blocks it.
- Local state has no sharing or backup. In teams, a remote backend handles that (future lab).

Reference: [Terraform State Docs](https://developer.hashicorp.com/terraform/language/state)

### terraform destroy

`terraform destroy` runs the loop in reverse: it reads the state, plans the deletion of every tracked resource, shows the plan, asks for confirmation, then deletes.

The plan summary will show something like:
```console
Plan: 0 to add, 0 to change, 1 to destroy.
```

After confirming with `yes`:
```console
Destroy complete! Resources: 1 destroyed.
```

After destroying:
- `terraform state list` returns nothing (the state file remains, but tracks no resources)
- `aws s3 ls --endpoint-url http://localhost:4566` no longer shows the bucket

Key properties:
- Destroy works from **state**, not just config — any resource still tracked gets deleted.
- If I delete a resource block from my `.tf` files, the next `plan` will propose destroying it anyway (`1 to destroy`). Removing code is still a change Terraform wants to apply.
- Keep `provider.tf` (and Floci running) until after destroy — the provider is needed to delete the resources too.
- `-auto-approve` skips the confirmation prompt. Never use it casually.
- Real AWS nuance: a non-empty S3 bucket refuses to delete unless `force_destroy = true` is set on the resource.
- There is no undo — this is exactly why reviewing the plan matters.

Reference: [Terraform Destroy Docs](https://developer.hashicorp.com/terraform/cli/commands/destroy)
