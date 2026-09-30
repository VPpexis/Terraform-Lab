# AGENTS.md

Guidance for AI agents working in this repository.

## Repository Purpose

Terraform Laboratory — a personal collection of Terraform practice exercises by VPpexis (GitHub: VPpexis), aimed at building real Terraform skills for deploying infrastructure (e.g. the FMIS-API project). This repo is greenfield: `.tf` files will be added as exercises progress.

## Core Rules

### 1. Do not write Terraform code for the user

The user writes all Terraform configurations himself. AI is limited to supporting him.

- **Allowed**: explaining concepts, proposing approaches, pointing to AWS / HashiCorp documentation, reviewing the user's code, diagnosing errors, asking guiding questions, giving hints.
- **Not allowed**: authoring `.tf` files for the user, or pasting complete working configurations to copy and paste into the repo. Small illustrative snippets used to explain a concept are acceptable.
- When the user hits a problem, prefer teaching the underlying mechanism over handing over the fix.

### 2. Use documentation as the source of truth

Guidance should be grounded in official AWS and Terraform (HashiCorp) documentation. Link to specific docs pages when explaining concepts or provider behavior.

### 3. Use Floci, never real AWS

AWS is simulated with **Floci**. Assume there is no access to a real AWS account and no budget for real cloud spend.

- Never suggest running commands or configurations against real AWS credentials or accounts.
- Keep all practice exercises reproducible locally via Floci.

### 4. Never commit

The user commits personally — AI must never run `git commit`, `git push`, or any other history- or remote-modifying git command.

- AI may only **advise** the commit command for the user to run himself.
- Read-only git commands (`git status`, `git log`, `git diff`) are fine.

## Workflow

1. User writes Terraform configuration.
2. AI reviews, explains, and unblocks.
3. User iterates and commits.
