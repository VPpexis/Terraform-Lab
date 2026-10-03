# Lab 03 — Variables, Outputs & tfvars

**Goal:** Refactor the hardcoded EC2 config from Lab 02 so inputs come from variables and results are exposed as outputs — the config becomes reusable, and the CLI feeds values in.

**What you will learn:** `variable` and `output` blocks, defaults vs required inputs, `.tfvars` files, variable precedence, and reading results with `terraform output`.

> Copy the config, not the state. This lab starts a **brand-new instance** with a fresh local state — Lab 02's instance should already be destroyed.

---

## Prerequisites

- [ ] Lab 02 done, and its resources destroyed (`terraform destroy` in `labs/02-ec2-basics`)
- [ ] Floci running and healthy (http://localhost:4566)
- [ ] Read the [Terraform variables docs](https://developer.hashicorp.com/terraform/language/values/variables) and [outputs docs](https://developer.hashicorp.com/terraform/language/values/outputs)

---

## Mission Checklist

- [ ] **1. Set up the folder** — copy `provider.tf` and `main.tf` from `labs/02-ec2-basics` into this folder (**not** `terraform.tfstate`, **not** `.terraform/`), then `terraform init`
- [ ] **2. Write `variables.tf`** — extract the hardcoded values from `main.tf` into `variable` blocks:
  - `instance_type` — `string`, `default = "t2.micro"`, short `description`
  - `instance_name` — `string`, **no default** (on purpose)
  - `ami_id` — `string`, `default = "ami-alpine"` (feed it into your `data "aws_ami"` filter)
  - reference: [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [ ] **3. Rewire `main.tf`** — replace the literals with `var.instance_type`, `var.instance_name`, `var.ami_id` (including inside the data source filter and the `Name` tag)
- [ ] **4. Run `terraform validate`, then `terraform plan`** — with no `.tfvars` yet, watch what Terraform does about `instance_name` (no default). Don't just accept the prompt — understand why it appears.
- [ ] **5. Write `terraform.tfvars`** — set `instance_name = "..."` to whatever you like. Plan again: notice it is auto-loaded, no flags needed.
  - reference: [tfvars files](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files)
- [ ] **6. Write `outputs.tf`** — expose:
  - `instance_id` ← `aws_instance.example.id`
  - `instance_private_ip` ← `aws_instance.example.private_ip`
  - reference: [Output Values](https://developer.hashicorp.com/terraform/language/values/outputs)
- [ ] **7. `apply`, then read results** — `terraform output`, then `terraform output -raw instance_id` (raw = scriptable)
  - reference: [`terraform output` command](https://developer.hashicorp.com/terraform/cli/commands/output)
- [ ] **8. Prove precedence** — change `instance_type` in `terraform.tfvars`, plan → update in place. Then override at the CLI with `-var="instance_type=t3.micro"`, plan again → CLI wins.
- [ ] **9. Clean up:** `terraform destroy`, then run `terraform output` and see what an empty state reports

---

## Guiding Questions

1. When a variable is set in several places at once (default, `terraform.tfvars`, `-var`, `TF_VAR_` environment variable), what is the precedence order? Which one wins?
2. Why did Terraform ask you for `instance_name` before `.tfvars` existed? What does a required variable mean for a CI pipeline where nobody can type an answer?
3. Outputs vs `terraform state show`: both show values — so why do outputs exist as a separate feature? (Hint: scripting with `-raw`/`-json`, and modules much later.)
4. In Lab 02 you edited `main.tf` to change `instance_type`; now you only edit an input value. Same result in the plan — which workflow is easier to review and audit in a pull request, and why?
5. Where do output values actually live — config, plan, or state? What does `terraform output` report after `destroy`?
6. What should never go in a committed `.tfvars` file? (Hint: inputs are how secrets usually enter Terraform.)

---

## Stretch Goals (optional, after the checklist)

- Add a `validation` block to `instance_type` so only `t2.*` / `t3.*` values pass.
- Add `project` and `environment` variables, then compose the `Name` tag in a `locals` block: `"${var.project}-${var.environment}"`.
- Override an input via environment variable: `TF_VAR_instance_type=t3.micro terraform plan`.
- Add an `instance_public_ip` output — then explain why it is empty (hint: `associate_public_ip_address`).

---

## Docs

- [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Output Values](https://developer.hashicorp.com/terraform/language/values/outputs)
- [`terraform output` command](https://developer.hashicorp.com/terraform/cli/commands/output)
- [Floci — Terraform with Floci](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md)
- [aws_instance resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)

---

## Rules of the Lab

- **You write all `.tf` code.** AI explains, reviews, and hints — it does not author configurations.
- Never commit state files (already covered by the root `.gitignore`).
- Never point Terraform at real AWS — Floci only.
- Run `terraform fmt` before committing.

## Learnings

### terraform output

`terraform output` reads the **outputs recorded in state** and prints them — it does not re-run anything or re-read the `.tf` files. After `apply`, outputs are also printed automatically at the end of the run; the command is how you fetch them later.

Commands:

```console
terraform output                    # all outputs, human-readable
terraform output instance_id        # one output (quoted string)
terraform output -raw instance_id   # no quotes — script-friendly
terraform output -json              # all outputs as JSON (for jq / CI)
```

Example from this lab:

```console
$ terraform output
instance_id = "i-8bb94112e86b45372"

$ terraform output -raw instance_id
i-8bb94112e86b45372
```

The difference matters: plain output wraps strings in quotes, `-raw` strips them so the value can be piped straight into another command.

Key properties:
- Outputs are stored in **state at apply time** — after adding an `output` block, `plan` shows *Changes to Outputs* even when no resource changes; `apply` is what records them.
- `-raw` only works for string outputs; lists/maps/objects need `-json`.
- `sensitive = true` hides the value in CLI output, but it is still **plaintext in state** — outputs are not a secret store.
- After `terraform destroy` there is nothing to read — the values referenced resources that no longer exist.
- It is read-only — safe to spam anytime.

**When do I actually use these?**
- **Scripting / CLI chaining** — grab an id or IP without scrolling through `state show`, e.g. `docker inspect $(terraform output -raw instance_id)`.
- **CI pipelines** — `-raw` / `-json` are the stable machine-readable interface.
- **Cross-config sharing** — later, another config or module consumes outputs instead of hardcoded values.

Outputs vs `terraform state show`: `state show` dumps **every** recorded attribute of a resource; outputs are only the **deliberate values I chose to expose** — a named interface, which is why the names should be meaningful.

Reference: [terraform output docs](https://developer.hashicorp.com/terraform/cli/commands/output)
