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

_(Fill this in as you go — your own words stick best.)_
