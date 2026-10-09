# Lab 04 — EC2 user_data & Bootstrapping

**Goal:** Launch an EC2 instance whose `user_data` script runs at boot, verify the script really executed inside the Docker-backed instance, and learn how Terraform treats script changes.

**What you will learn:** the `user_data` argument, first-boot semantics, `file()` + `path.module`, in-place vs replace on user_data changes, and how Floci executes user data compared to real cloud-init.

> This is the lab that needs the **Docker socket**. Until Floci can reach Docker, instances have no backing container — and a bootstrap script with nothing to execute in is just a ghost. The fix is mission #1.

---

## Prerequisites

- [ ] `docker-compose.yaml` gives Floci the Docker socket, and Floci was recreated (see mission #1)
- [ ] Docker running and `docker ps` works
- [ ] Floci healthy (http://localhost:4566)
- [ ] Lab 03 done, resources destroyed, and its `plan.out` cleanup resolved
- [ ] Read the [Floci EC2 docs — UserData & IMDS sections](https://floci.io/floci/services/ec2/) and the [AWS user data guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)

---

## Mission Checklist

- [ ] **1. Fix the compose file (the real prerequisite)** — add the Docker socket bind mount to the `floci` service volumes:
  - `/var/run/docker.sock:/var/run/docker.sock`
  - then recreate Floci: `docker compose down && docker compose up -d`
  - verify: `docker info` works, and Floci logs no longer mention "No Docker daemon is reachable"
- [ ] **2. Set up this folder** — copy `provider.tf`, `variables.tf`, `main.tf`, `output.tf` from `labs/03-variables-outputs` (**not** state, **not** `.terraform/`, **not** `plan.out`), then `terraform init`
- [ ] **3. Write `user-data.sh`** in this folder — a small script that leaves proof it ran:
  - `#!/bin/sh` shebang (Alpine is BusyBox — `sh`, not bash)
  - write something to a marker file (your choice of path) and/or `echo` to stdout
  - hint: whatever it writes must be verifiable later with `cat` inside the container
- [ ] **4. Wire it into `main.tf`** — add `user_data = file("${path.module}/user-data.sh")` to `aws_instance.example`, then `terraform fmt` + `terraform validate`
- [ ] **5. Run `terraform plan`** — before applying, find `user_data` in the output: is it set at plan time or `(known after apply)`? Which instance attributes are still unknown?
- [ ] **6. Apply, then catch the script in the act** (three angles):
  - `docker ps` → the instance container (contrast with the Floci server container)
  - `docker exec -it <container> cat /tmp/user-data.sh` — Floci copies your script there (2.1.0; docs claim `/var/lib` — trust your eyes)
  - `docker exec -it <container> cat <your marker file>` — proof it executed
  - bonus: `docker exec -it <container> curl -s http://169.254.169.254/latest/user-data`
- [ ] **7. First-boot experiment:**
  - edit the script text → `terraform plan`: is `user_data` a `~` update or a `-/+` replacement?
  - `apply`, then check the container: did the script re-run this time?
  - now set `user_data_replace_on_change = true`, plan again → you should see `-/+`. Apply and observe: new instance, new container, script ran again
- [ ] **8. Clean up:** `terraform destroy`, then `docker ps` — the instance container should be gone (Floci keeps terminated instances queryable for ~1 hour as tombstones, but the container is removed)

---

## Guiding Questions

1. On real AWS, **who** actually executes user_data, and when? How is Floci's implementation ("executes the script directly after SSH key injection") different from cloud-init?
   > On real AWS, **cloud-init** (the boot agent inside the OS) executes it — as root, once, at the instance's first boot. Terraform only hands the script to the API during apply; it does not run it, does not wait for it, and can report success even if the script fails. Floci skips cloud-init entirely: it decodes the user data and executes the script directly after SSH key injection, with the shebang choosing the interpreter.
2. Why does changing `user_data` update the instance **in place** by default — and why does the script not re-run? What exactly does `user_data_replace_on_change = true` change, and which plan symbol reveals it?
   > `user_data` is only *consumed* at launch — cloud-init won't run again on a live instance no matter how many times the text changes. By default the provider updates the stored attribute in place (`~`), and the new text just sits there, dead. `user_data_replace_on_change = true` tells the provider to **replace the instance** when user_data changes, which plan shows as `-/+` (destroy + recreate). The flag doesn't re-run the script — it creates a new instance, whose first boot runs it.
3. Why is `user_data` a terrible place for secrets? (Two leaks: one inside the instance, one in Terraform state.)
   > The problem is readability, not just encryption: anyone with a shell or process on the instance can fetch it from IMDS (`/latest/user-data`, plain local HTTP — no TLS), any SSRF bug in an app can too, anyone with `ec2:DescribeInstanceAttribute` or console access can read it, and it is stored in **plaintext in Terraform state**. It's not encrypted at rest either. Secrets belong in Secrets Manager / SSM Parameter Store, fetched at boot using the instance role.
4. `file()` vs an inline heredoc vs `templatefile()` — what does each buy you, and why is `path.module` used in the file path?
   > - `file()` reads a static file and returns its contents as a string — no interpolation; `${...}` inside the file stays literal.
   > - An inline heredoc embeds the script in the `.tf` itself — workable for 3 lines, painful for real scripts (no linting, noisy diffs, no reuse).
   > - `templatefile()` reads a file and renders `${...}` placeholders with values from Terraform — the tool for scripts that need `var.instance_name` etc.
   > - `path.module` anchors the path to the module's own directory instead of the shell's current working directory, so the config works from anywhere and inside modules. (Docs caution: avoid it in *write* operations — multiple invocations of a local module share the same source dir, causing race conditions. Reads are the recommended use.)
5. In the plan, `user_data` is known immediately but `id` and `private_ip` are `(known after apply)`. What decides which attributes fall in each bucket?
   > The rule: `(known after apply)` = the remote system decides the value during creation. `user_data` is my own file's text, so plan knows it. `id`, `private_ip`, and `public_ip` are generated or allocated by AWS/Floci at create time, so they're unknown placeholders until apply.
6. What did the Docker socket mount actually change about what Floci can do? Connect it back to the "ghost instance" from Lab 02.
   > Before the mount, Floci could only update its internal control-plane metadata — no Docker daemon access, so "running" instances had no backing container (Lab 02's `i-647cd3e5b041ca409` was exactly that). After mounting `docker.sock`, Floci talks to the host Docker daemon and launches a **real container per instance** (docker-outside-of-docker). That's also why the mount is root-equivalent — the socket is the keys to the whole Docker engine. And it's why user_data had nowhere to run before: there was no OS.

---

## Stretch Goals (optional, after the checklist)

- Use `templatefile()` so the script receives `var.instance_name` (e.g. write it into the marker file).
- Preview Lab 05: open TCP port 80 in a security group and start `busybox httpd -f -p 80` from user_data — Floci publishes the port on the host (watch for `Published EC2 instance ... app port 80 on host port 30000` in the logs) so you can `curl` it.
- Compare `user_data = file(...)` with `user_data_base64 = base64encode(file(...))` — which one does the provider encode for you?
- SSH into the container with an injected key pair (host ports 2200–2299) — deep preview of a future lab.

---

## Docs

- [Floci — EC2 (UserData, IMDS, containers)](https://floci.io/floci/services/ec2/)
- [AWS — Run commands on your Linux instance at launch](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/)
- [aws_instance resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [`file` function](https://developer.hashicorp.com/terraform/language/functions/file)
- [`templatefile` function](https://developer.hashicorp.com/terraform/language/functions/templatefile)
- [path.module reference](https://developer.hashicorp.com/terraform/language/expressions/references#filesystem-and-workspace-info)

---

## Rules of the Lab

- **You write all `.tf` code.** AI explains, reviews, and hints — it does not author configurations.
- Never commit state files (already covered by the root `.gitignore`).
- Never point Terraform at real AWS — Floci only.
- Run `terraform fmt` before committing.

## Learnings

### user_data

`user_data` is the boot-time bootstrap hook: a script (or cloud-config) handed to the instance at launch. On real AWS, cloud-init runs it **as root, once, at first boot**; Floci skips cloud-init and executes the script directly after SSH key injection. Terraform only passes the string — it never learns whether the script succeeded.

How I wired it:

```hcl
user_data = file("${path.module}/user-data.sh")
```

And the script itself:

```sh
#!/bin/sh

echo "Hello Van" > /tmp/output.txt
```

Proof of execution (Floci):
- `docker ps` → a real container backs the instance
- `docker exec -it <container> cat /tmp/output.txt` → the marker file
- Floci keeps its own copy at `/tmp/user-data.sh` (the docs say `/var/lib/user-data.sh` — in 2.1.0 it's `/tmp`; verify, don't trust)

Key properties:
- Executed once per instance lifetime; changing the script later does NOT re-run it.
- Default Terraform behavior on change: in-place update (`~`). Add `user_data_replace_on_change = true` to force replacement (`-/+`).
- The AWS API requires base64; the provider encodes plain `user_data` for me (`user_data_base64` exists if I encode myself).
- Real AWS limit: 16 KB raw, before base64.
- Never secrets: readable inside the instance via IMDS, and visible in plaintext in state.
- No success/failure feedback to Terraform — apply can succeed while the script fails.

Reference: [aws_instance resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance), [AWS user data guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html), [Floci EC2 docs](https://floci.io/floci/services/ec2/)

### file()

Reads a file from disk at plan time and returns its contents as a string. The file must exist when the run **starts** — functions don't participate in the dependency graph, so `file()` can't read something another resource generates during apply.

Key properties:
- Contents are used verbatim — `${...}` inside the file stays literal (that's `templatefile()`'s job).
- Should be anchored with `path.module` for robustness.
- Related functions: `filebase64`, `fileexists`, `fileset`, `templatefile`.

Gotcha I hit: `file("${path.module/user-data.sh}")` — putting the `/` inside the interpolation made Terraform evaluate it as an expression, and it errored with "managed resource `user-data` `sh` has not been declared". The brace closes right after `path.module`: `"${path.module}/user-data.sh"`.

Reference: [file function docs](https://developer.hashicorp.com/terraform/language/functions/file)

### path.module

The filesystem path of the module where the expression is placed. It anchors relative paths to the config's own directory instead of the shell's CWD, so the same config works no matter where `terraform` is invoked from — and (crucially) it also works inside modules, where `./` would point at the wrong directory.

Key properties:
- `file("./user-data.sh")` only works if I always run terraform from this folder; `${path.module}/...` always works.
- Docs caveat: don't use it for **write** operations — multiple invocations of a local module share the same source directory, so writes can race and overwrite each other. It's perfect for reads.
- Siblings: `path.root` (root module dir) and `path.cwd` (where terraform was invoked) — use sparingly; they tie the config to the machine/directory layout.

Reference: [References — Filesystem and Workspace Info](https://developer.hashicorp.com/terraform/language/expressions/references#filesystem-and-workspace-info)
