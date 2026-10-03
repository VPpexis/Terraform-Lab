 # Terraform Laboratory

 A Collection of Terraform Practices to improve in terraforming.

 Since Me(VPpexis) is very BANO in Terraform. I will dedicated this repository in improving my Terraform. Terraform is crucial for deploying infrastructure fast and quickly. Therefore, learning it is important to learn how it works and avoid infrastructure holes and bugs.

 I realized I was bano when I tried deploying my FMIS-API Project in AWS and it gave me intense headache and nose bleed (overexagration) that it turned me into a Pokemon (not based on a true story).

 ## Requirements
  
  - This will practice will be guided both with **AI** and **AWS Documentations**.
  - AI is limited only in supporting me as much as possible and avoid coding for me.
  - **Floci** will be used to simulate AWS since **I AM VERY VERY BROKE**.

 ## Common Commands

 Commands used across my lab experiments — worth understanding their flags and use cases.

 > AWS CLI commands talk to Floci: add `--endpoint-url http://localhost:4566` (or export `AWS_ENDPOINT_URL`), and set dummy creds `AWS_ACCESS_KEY_ID=test` / `AWS_SECRET_ACCESS_KEY=test` (see [Floci AWS CLI setup](https://floci.io/floci/getting-started/aws-setup/)).

 ### Terraform — core workflow

 | Command | What it does | Docs |
 |---|---|---|
 | `terraform init` | Sets up the working directory: downloads providers, configures the backend, writes the lock file | [Docs](https://developer.hashicorp.com/terraform/cli/commands/init) |
 | `terraform fmt` | Rewrites `.tf` files into canonical formatting (indentation, alignment, newlines) | [Docs](https://developer.hashicorp.com/terraform/cli/commands/fmt) |
 | `terraform validate` | Checks syntax and internal consistency without touching infrastructure | [Docs](https://developer.hashicorp.com/terraform/cli/commands/validate) |
 | `terraform plan` | Dry run: refreshes state and previews every change `apply` would make | [Docs](https://developer.hashicorp.com/terraform/cli/commands/plan) |
 | `terraform plan -out=tfplan` → `terraform apply tfplan` | Saves a reviewed plan and applies exactly that plan | [Docs](https://developer.hashicorp.com/terraform/cli/commands/plan#out-filename) |
 | `terraform apply` | Executes the planned changes after confirmation | [Docs](https://developer.hashicorp.com/terraform/cli/commands/apply) |
 | `terraform destroy` | Deletes every resource tracked in state after confirmation | [Docs](https://developer.hashicorp.com/terraform/cli/commands/destroy) |

 ### Terraform — state inspection

 | Command | What it does | Docs |
 |---|---|---|
 | `terraform state list` | Lists the resource addresses tracked in state (e.g. `aws_instance.example`) | [Docs](https://developer.hashicorp.com/terraform/cli/commands/state/list) |
 | `terraform state show <address>` | Prints the recorded attributes of one resource | [Docs](https://developer.hashicorp.com/terraform/cli/commands/state/show) |

 ### AWS CLI (against Floci)

 | Command | What it does | Docs |
 |---|---|---|
 | `aws sts get-caller-identity` | Confirms which account/identity the CLI is using | [Docs](https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html) |
 | `aws s3 ls` | Lists buckets | [Docs](https://docs.aws.amazon.com/cli/latest/reference/s3/ls.html) |
 | `aws ec2 describe-images` | Lists AMIs; supports `--filters` and `--owners` | [Docs](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html) |
 | `aws ec2 describe-instances` | Lists EC2 instances and their state | [Docs](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html) |

 ### Floci & Docker

 | Command | What it does | Docs |
 |---|---|---|
 | `docker compose up -d` | Starts Floci in the background | [Docs](https://docs.docker.com/reference/cli/docker/compose/up/) |
 | `docker compose down` | Stops and removes the Floci container | [Docs](https://docs.docker.com/reference/cli/docker/compose/down/) |
 | `docker compose logs -f` | Follows Floci logs (check these when EC2 misbehaves) | [Docs](https://docs.docker.com/reference/cli/docker/compose/logs/) |
 | `docker ps` | Lists running containers — Floci runs one per EC2 instance | [Docs](https://docs.docker.com/reference/cli/docker/container/ls/) |
 | `docker exec -it <container> sh` | Opens a shell inside a Floci-created instance container | [Docs](https://docs.docker.com/reference/cli/docker/container/exec/) |

 ### Shell helpers

 | Command | What it does | Docs |
 |---|---|---|
 | `grep -i -A3 <pattern> <file>` | Case-insensitive search with 3 lines of context after the match | [Docs](https://man7.org/linux/man-pages/man1/grep.1.html) |