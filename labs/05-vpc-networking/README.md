# Lab 05 — VPC Networking & Security Groups

**Goal:** Build your own network from scratch — VPC, public subnet, internet gateway, route table, security group — and place your EC2 instance inside it, serving a web page you can `curl` from your host machine.

**What you will learn:** the core VPC building blocks, what actually makes a subnet "public", implicit dependencies (resource references) in the graph, and security group behavior (in-place rule changes).

> Floci seeds a default VPC, subnets, IGW and SG (like real AWS does) — this lab **ignores all of them** and builds its own. For the web server, Floci publishes SG-opened TCP ports on your host (socat, ports 30000–30999) and logs the mapping, so `curl` will work.

---

## Prerequisites

- [ ] Lab 04 done, resources destroyed, and committed
- [ ] Floci healthy with the Docker socket mount (http://localhost:4566)
- [ ] Read [Floci EC2 — Security Group Port Publishing + Default Resources](https://floci.io/floci/services/ec2/) and the [AWS VPC guide](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)

---

## Mission Checklist

- [ ] **1. Set up this folder** — copy the config from `labs/04-ec2-user-data` (**not** state, **not** `.terraform/`, **not** `tfplan`), then `terraform init`
- [ ] **2. Create `network.tf`** — all the plumbing goes in its own file (any `.tf` file loads as one config; organizing by concern is looksmaxxing):
  - `aws_vpc` with your own CIDR block (e.g. `10.0.0.0/16`)
  - `aws_subnet` with a smaller CIDR inside it (e.g. `10.0.1.0/24`)
  - give both a `Name` tag — capital N this time, soldier 🫡
- [ ] **3. Internet gateway** — `aws_internet_gateway`, then attach it to your VPC (`vpc_id` reference)
- [ ] **4. Route table** — `aws_route_table` in the VPC + a `0.0.0.0/0` route pointing at the IGW, then `aws_route_table_association` linking it to your subnet
  - reference: [aws_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)
- [ ] **5. Security group** — `aws_security_group` in the VPC with an inbound rule allowing **TCP 80 from `0.0.0.0/0`** (egress defaults to allow-all)
  - hint: a fresh SG denies all inbound by default — the rule is the point
- [ ] **6. Rewire the instance** — `subnet_id = aws_subnet.<name>.id` and `vpc_security_group_ids = [aws_security_group.<name>.id]` on `aws_instance`
- [ ] **7. Web server via user_data** — update `user-data.sh` to write a small `index.html` and start a server on port 80:
  - Alpine's BusyBox includes `httpd` — you don't need to install anything
  - it must listen on `0.0.0.0` (not `127.0.0.1`) and be **backgrounded** (`&`) or the script never finishes
- [ ] **8. Run the loop and verify from three angles:**
  - `terraform state list` → all resources, one address each
  - `docker ps` → the instance container still exists
  - `docker logs terraform-lab-floci-1 --tail 50` → look for `Published EC2 instance ... app port 80 on host port 30xxx`, then **`curl http://localhost:30xxx`** — your own VPC served you a page
  - bonus: `docker exec -it <container> wget -qO- localhost`
- [ ] **9. Security group experiment:** remove the port 80 ingress rule → `terraform plan` (watch the symbol) → `apply` → `curl` fails (Floci revokes the forward) → re-add the rule → works again. No instance replacement either time.
- [ ] **10. Clean up:** `terraform destroy` — before confirming, read the order it plans to delete in. Then `docker ps` and `curl` one last time.

---

## Guiding Questions

1. You referenced `aws_vpc.<name>.id` (and other resources) instead of pasting IDs. What does a reference create **beyond** passing a value? Think ordering — both on apply and on destroy.
2. What actually makes a subnet "public" in AWS? Walk the chain: subnet → route table → IGW. What happens if you skip the route table association?
3. A brand-new security group denies all inbound traffic — yet your `curl` from the host worked. What did Floci do under the hood, and how does that translate to real AWS (where there are no socat sidecars)?
4. `terraform destroy` deleted the instance before the subnet and VPC, without you specifying any order. Why does that "just work"?
5. SG rule change: did plan show `~` or `-/+`? Why don't security group changes require instance replacement, while changing `subnet_id` would? (Stretch: try the subnet change and watch `-/+`.)
6. In Lab 02 the instance launched in the default VPC for free. What did building your own VPC buy you — and what does a *production* VPC (FMIS-API style) have that this one still doesn't? (NAT gateways, private subnets, multi-AZ, NACLs…)

---

## Stretch Goals (optional, after the checklist)

- Move CIDRs into variables and build `Name` tags from a `locals` block (e.g. `"${var.project}-vpc"`).
- Add a second subnet in a different AZ (`us-east-1a`/`b`/`c` are available) and move the instance — observe the `-/+` replacement.
- Create a key pair, allow SSH (22) in the SG, and SSH into the container (host ports 2200–2299). Note: SSH is never socat-forwarded — Floci wires it directly.
- Try `terraform graph` (DOT output) to *see* the dependency graph; pipe it through Graphviz if installed.
- Write the ingress rule with a description and a narrower CIDR than `0.0.0.0/0` — Floci won't enforce the source, but write it like production would.

---

## Docs

- [Floci — EC2 (Security Group port publishing, VPC behaviors)](https://floci.io/floci/services/ec2/)
- [AWS — What is Amazon VPC?](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [AWS — Configure subnets (public/private)](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html)
- [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)
- [aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway)
- [aws_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association)
- [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
- [Terraform — Resource dependencies](https://developer.hashicorp.com/terraform/language/resources/behavior#resource-dependencies)

---

## Rules of the Lab

- **You write all `.tf` code.** AI explains, reviews, and hints — it does not author configurations.
- Never commit state files (already covered by the root `.gitignore`).
- Never point Terraform at real AWS — Floci only.
- Run `terraform fmt` before committing.

## Learnings

### CIDR & subnet sizing

- In `/N`, the first N bits are locked as the network; hosts = 2^(32−N): `/16` → 65,536, `/24` → 256, `/28` → 16.
- AWS allows VPC blocks from **/16 (largest) to /28 (smallest)** — a `/15` (131,072 addresses) gets rejected in real AWS even if Floci shrugs.
- AWS reserves **5 addresses per subnet** (network address, router, DNS, future use, broadcast), so a `/28` leaves 11 usable.

### What actually makes a subnet "public"

- Public-ness is not a switch — it's a **consequence of routing**. The chain: subnet → associated route table → route `0.0.0.0/0` → internet gateway. Has a path to the IGW ⇒ public subnet.
- Every subnet always has a route table: mine if I associate one, otherwise the VPC's **main route table** (which only holds the local VPC route). No IGW route ⇒ no internet path ⇒ effectively private. A production "private" subnet usually adds a NAT route for egress.
- Instance private IPs are handed out from the subnet's CIDR automatically; DNS/DHCP configuration lives at the **VPC level** (DHCP option sets), not per-subnet. `map_public_ip_on_launch` just auto-assigns public IPs — it creates no routing.

### Implicit dependencies & ordering

- Referencing `aws_vpc.main.id` doesn't just pass a value — it creates an **implicit dependency** (an edge in the dependency graph).
- **Dependencies** = what a resource needs (subnet depends on VPC → VPC gets created first). **Dependents** = what needs it (the VPC's dependents include the subnet, IGW, route table).
- Create order runs dependencies first; destroy runs **dependents first** (the graph in reverse). That's why `terraform destroy` deletes instance → subnet → VPC correctly without me specifying anything.

### Mutable vs ForceNew → `~` vs `-/+`

- Mutable attributes update **in place** (`~`): security group rules can be authorized/revoked on a live ENI anytime, so my ingress-rule change never touched the instance.
- **ForceNew** attributes replace (`-/+`): an instance's placement is immutable — `subnet_id` cannot change after creation — so Terraform destroys and recreates. (The *subnet* itself is modifiable; it's the instance's placement in it that isn't.)
- Habit: in provider docs, every "Forces new resource" note is a replacement trigger.

### Security groups — the real thing

- An SG is a virtual firewall attached to an instance's **ENI** (network interface), not "the instance" itself — and it's **stateful**: allow a request in and the reply automatically flows out (connection tracking), no mirrored rule needed.
- **Allow-list only**: nothing is denied *explicitly*; anything not matched by an allow rule is **implicitly denied**. Explicit deny rules — and stateless behavior — belong to NACLs, which sit at the subnet level.
- A fresh SG's default posture: **no inbound rules, allow-all egress**.
- Multiple SGs on one instance = the **union** of all their rules — no SG can subtract a rule another one allows.
- Rule anatomy: protocol + port range + **source** — and the source is *the client*, not me: `0.0.0.0/0` = any internet client; the VPC CIDR = only machines inside my own network. A source can also be another security group (`referenced_security_group_id`) — that's how tiers will talk in future labs (ALB → app → DB) — or a prefix list.
- Terraform shapes: `aws_security_group` is the container; rules are either inline `ingress {}` blocks **or** separate `aws_vpc_security_group_ingress_rule` resources (what this lab used — one rule per resource, clean diffs and reviews). Don't mix the two styles on the same SG — they fight over the rule set.
- Rules are **mutable**: authorize/revoke works on a live ENI anytime ⇒ plan shows `~` and the instance never notices. The SG's own `name` is ForceNew though — renaming replaces the group (hence `name_prefix` exists to avoid collisions).
- Least privilege: `0.0.0.0/0` on port 80 is normal for a public web server; the same on SSH (22) or a database port is how machines get found and brute-forced.

### Floci's emulation gap (SG edition)

- Floci **models** SGs — stores rules, serves them through the API — but by default does **not enforce** them on packets. Instead, a CIDR-sourced TCP rule acts as a signal to publish: Floci starts an `alpine/socat` sidecar and maps a host port (`Published EC2 instance ... app port 8080 on host port 30,000`).
- The rule's source CIDR isn't checked, and a port opened *only* to a referenced security group (no CIDR) isn't published on the host at all.
- Real AWS has no sidecars: packets traverse the IGW to the instance's public IP and the SG filters them at the ENI. Emulator "reachability" ≠ production "filtering" — so I still write rules as production would judge them.

### Bug hunt: "Address in use" on port 80

- `user_data` running `httpd -p 80` failed with exit code 1: `bind: Address in use`, and `curl` showed *Empty reply from server*.
- `netstat` inside the instance revealed `169.254.169.254:80 LISTEN` — that's **Floci's in-container IMDS proxy**, squatting on port 80. Binding `0.0.0.0:80` collides with it.
- On real AWS, IMDS is not a local listener on the instance — port 80 is free for web servers. This was an **emulation boundary**, not a config mistake.
- Fix: serve on another port (`8080`), update the SG rule, and recreate the instance (`terraform apply -replace=...`) because user_data only runs at first boot (Lab 04 callback).

### Victory lap: the full chain

`curl localhost:30000` → socat sidecar → Floci VPC Docker network → instance `10.0.1.12:8080` → busybox httpd → `/var/www/index.html` → **HTTP 200 "Hello World"** — a real request path from my Mac into a network I built myself, emulated end to end.

References: [AWS VPC CIDR blocks](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html), [AWS subnet configuration](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html), [Floci EC2 (SG publishing)](https://floci.io/floci/services/ec2/)
