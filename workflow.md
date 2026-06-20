# DevOps Learning System – Workflow Guide

This file defines how to use your DevOps learning system with Copilot.

It ensures:
- Consistent progress
- Real skill development
- Continuous improvement through feedback

---

## ⚠️ Source Usage Rule

- Nigel Poulton → base concepts and examples
- KodeKloud → guided exercises
- Always extend both into production-grade EKS scenarios

Never use sources as-is without upgrading them


# 🧠 Core Principles

- Hands-on work > theory
- Always think production-first
- Always ask: "What would break in real-world?"
- Depth over speed
- Learning = build + break + debug + improve

---

# 🔁 Daily Workflow

Follow this every session, every time.

---

## 🚀 SESSION START (do this first, before anything else)

Do not manually inspect every file unless something looks inconsistent.

Instead, ask Copilot to read the source-of-truth files and come back with one recommended next task.

Files Copilot should always review:
1. `progress/log.md`
2. `roadmap/eks-2-week-focused.md`
3. `skills_matrix.md`
4. Active goal file in `goals/` if one exists for the current focus

Rules for session start:
1. One task only. One lab, one concept, or one failure scenario.
2. Copilot must return a recommendation, not a menu of five options.
3. Copilot must include the exact first command to run.
4. Manually override only if you have a strong reason.
5. If the task includes Terraform or AWS CLI, run daily sandbox preflight first.

Daily Terraform sandbox preflight (MANDATORY on any new Terraform day):
1. Regenerate/restart KodeKloud AWS sandbox credentials.
2. Update `~/.aws/credentials` profile `kodekloud-sandbox`.
3. Verify access before any Terraform command:

```bash
aws sts get-caller-identity --profile kodekloud-sandbox
```

4. Verify EKS prerequisite IAM permission (required for cluster creation):

```bash
AWS_PROFILE=kodekloud-sandbox aws --no-cli-pager iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<ACCOUNT_ID>:user/<IAM_USER> \
  --action-names iam:PassRole \
  --resource-arns arn:aws:iam::<ACCOUNT_ID>:role/lab01-eks-cluster-role
```

If `EvalDecision` is not `allowed`, do not run Lab-01 Terraform apply in that sandbox.

Rule: never run Terraform in this repo without explicit sandbox profile:

```bash
AWS_PROFILE=kodekloud-sandbox terraform <command>
```

Ask Copilot:

```text
Session Start Check

Review:
- progress/log.md
- roadmap/eks-2-week-focused.md
- skills_matrix.md
- relevant file in goals/

Return:
- current context: <kctx output if relevant>
- active phase/day
- what was last completed
- top 1 recommended next task
- why this is the priority now
- exact first command to run
```

---

## 🏁 SESSION END (do this before closing)

Do not manually close the session file-by-file unless something looks wrong.

Instead, ask Copilot to review the session outcome and propose the closeout updates.

Copilot should:
1. Propose the `progress/log.md` entry
2. Propose `skills_matrix.md` changes only where evidence exists
3. Propose the exact `Next action` line with one exact first command
4. Check consistency across roadmap, goals, and progress files
5. Then help commit and push

Log presentation rule (MANDATORY):
1. Keep one consolidated entry per date in `progress/log.md`.
2. If the same day has multiple restarts/sessions, append to that day entry in chronological order instead of creating a new date block.
3. Keep one `Next action` at the end of the consolidated date entry.

Commit and push to GitHub:

```bash
cd /Users/disi01/Documents/GitHub/Skills-Workspace
git add -A
git commit -m "YYYY-MM-DD: lab-XX completed, skills updated"
git push
```

Ask Copilot:

```text
Session End Check

Review:
- progress/log.md
- skills_matrix.md
- active roadmap file
- relevant goal file

Return:
- proposed log entry
- exact skill changes with justification
- confidence (1-5)
- exact next action line
- exact first command for next session
```

Session end template (copy/paste):
```text
Session End Check
- Validation checklist: <passed/total>
- Failure scenarios diagnosed without fix-first: <count>
- Confidence (1-5): <score>
- Next action (single exact command): <command>
```

---

## ✅ Accuracy Sync (MANDATORY after each session)

Before committing, ensure these are consistent:
1. `progress/log.md` current status header matches reality
2. Active roadmap status reflects current phase/day progress
3. `skills_matrix.md` levels and "Labs completed" count are updated
4. Goal progress file reflects current lab completion state

If any of the above are stale, update them in the same commit.

---

## ✅ Step 1 — Decide what to work on

Use the recommendation returned in `SESSION START`.

Before executing, confirm these four things:
1. The task is singular and concrete
2. The success criteria are clear
3. The first command is known
4. "Done for this session" is well-defined

If Terraform is involved, confirmation must include this preflight command output:

```bash
aws sts get-caller-identity --profile kodekloud-sandbox
```

Expected output from Copilot at this stage:
- Confirmed task for this session
- Success criteria
- First command to run
- Stop condition for the session

---

## ✅ Step 2 — Execute the work

Ask:

Guide me through this lab step-by-step.
Challenge me with:
- production scenarios
- potential failures
- scaling considerations

While working, actively ask:

- What would fail in production?
- What am I missing?
- How would this behave at scale?
- How would I debug this?

---

## ✅ Step 3 — Log your progress (MANDATORY)

After finishing:

Generate a log entry based on today’s work and update progress/log.md

Each log should include:
- What you did
- What failed / was difficult
- Key learnings
- Confidence level (1–5)
- Exact next action with one first command

Rule for `Next action` everywhere in this repo:
- Must name one concrete next task
- Must include one exact first command
- Can include one fallback option only if necessary

---

## ✅ Step 4 — After the lab (MANDATORY, not optional)

1. **Run the validation checklist** — every checkbox in the lab README must pass
2. **Hit at least 1 failure scenario without reading the fix first** — attempt to diagnose independently
3. **Update skills_matrix.md honestly** — only raise a score if you could explain the concept to someone else
4. Ask: *"What would I do differently if this were a production system?"*

---

## ⚠️ Failure-First Rule (applies to every lab, every failure scenario)

> **Attempt to diagnose the failure before reading the fix.**

Procedure:
1. Trigger the failure as described
2. Spend at least 5 minutes diagnosing with `kubectl describe`, `kubectl logs`, `kubectl get events`
3. Form a hypothesis
4. *Then* read the fix

If you read the fix first → your skill level stays where it was. You learned nothing.

---

# �️ Local Cluster & kubectl Context Safety

## Clusters

| Context name | What it is |
|---|---|
| `rancher-desktop` | Local training cluster (Rancher Desktop) |
| `apps-datasson-prod-euc1` | **WORK — PRODUCTION** |
| `apps-datasson-test-euc1` | Work — test |
| `lab-datasson-test-euc1` | Work — lab/test |

## Rule: always know where you're pointing

```bash
kctx          # print current context before any kubectl command
kuse-train    # switch to local training cluster
kuse-prod     # switch to prod — shows warning
```

## Aliases (these live in ~/.zshrc)

```bash
alias k="kubectl"
alias k-prod='kubectl config use-context apps-datasson-prod-euc1'
alias k-test='kubectl config use-context apps-datasson-test-euc1'
alias k-lab='kubectl config use-context lab-datasson-test-euc1'
alias k-view='kubectl config view'
alias kdpo='kubectl describe pods'
alias kgpo='kubectl get pods'
alias kl='kubectl logs'
alias ktno='kubectl top nodes'
alias ktpo='kubectl top pods'
alias ll='ls -ltr'
alias k-train='kubectl --context=rancher-desktop'   # run one-off cmd on training cluster without switching context
alias kctx='kubectl config current-context'
alias kuse-train='kubectl config use-context rancher-desktop && echo "NOW ON: rancher-desktop"'
alias kuse-prod='kubectl config use-context apps-datasson-prod-euc1 && echo "NOW ON: PROD - be careful"'
```

## For all labs in this workspace: use `k-train` for one-off commands, or `kuse-train` to switch, then `k`

---

# �🔁 KodeKloud Workflow (when using it)

---

## Step 0 — Check if a lab already exists (DO THIS FIRST)

Before starting any KodeKloud topic, ask:

Does a lab for this topic already exist in `labs/`?
- Yes → run that lab instead of creating a duplicate
- No → complete the KodeKloud exercise, then upgrade it

---

## Step 1 — Complete lab in KodeKloud

---

## Step 2 — Log it

Generate a KodeKloud progress entry and update sources/kodekloud/progress.md

---

## Step 3 — Upgrade it (CRITICAL STEP)

Ask:

I completed this KodeKloud lab.

Now:
- Identify real-world gaps
- Convert it into a production-grade EKS lab
- Add failure and debugging scenarios

✅ Never stop at KodeKloud level  
✅ Always extend to real-world use

---

# 📘 Nigel Poulton Workflow

When using book or repo examples:

---

## Step 1 — Understand the example

Ask:

Explain this example in a production EKS context

---

## Step 2 — Identify gaps

Ask:

What is missing for real-world usage?
What would break in production?

---

## Step 3 — Upgrade it

Ask:

Convert this into a production-grade lab using:
- EKS
- Terraform (if applicable)
- real-world constraints

---

# 📊 Skills Matrix Rules

Your skills_matrix.md is your truth.

Follow these rules:

- Score based only on real experience
- NOT based on theory
- Lower score if you struggled
- Increase score only if you:
  - built successfully
  - understood deeply
  - debugged issues

---

# 📅 Weekly Review (VERY IMPORTANT)

Do this once per week.

Ask Copilot:

Analyze:
- progress/log.md
- skills_matrix.md
- kodekloud progress

Identify:
- weak areas
- false confidence
- gaps vs production-level knowledge

Then:
- update skills_matrix.md
- adjust roadmap
- generate next labs

---

## 💸 Weekly Cost Hygiene (if cluster is running)

Do this alongside the weekly review to prevent surprise AWS bills:

```bash
# Namespaces with no running pods (safe to delete)
kubectl get ns --no-headers | awk '{print $1}' | \
  xargs -I{} kubectl get pods -n {} --no-headers 2>/dev/null | grep -v 'No resources'

# Orphaned EBS volumes (not attached to any pod)
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[].{ID:VolumeId,Size:Size,AZ:AvailabilityZone}'

# Active ALBs (each costs ~$0.008/hour = ~$5.76/month)
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[].{Name:LoadBalancerName,State:State.Code}'

# CloudWatch log groups without retention set (accumulate forever)
aws logs describe-log-groups \
  --query 'logGroups[?!retentionInDays].logGroupName'
```

Rule: **delete any namespace you're not actively using**. EBS volumes and ALBs persist after `kubectl delete` if the controller didn't clean up properly.

---

# ⚡ Key Prompts (Use Frequently)

---

## 🔹 Next task

What should I work on next based on my current progress?

---

## 🔹 Lab guidance

Guide me step-by-step and challenge me with real-world scenarios

---

## 🔹 Upgrade example

Turn this into a production-grade EKS scenario

---

## 🔹 Debug thinking

What would fail in production and why?

---

## 🔹 Skill evaluation

Evaluate my current skill level honestly and identify gaps

---

# 🚀 Golden Rule

If something feels easy:

👉 You are NOT going deep enough

Ask for:
- failure scenarios
- scaling considerations
- production constraints

---

# 🧩 System Loop (Mental Model)

Repeat continuously:

1. Learn (KodeKloud / Nigel)
2. Build (labs)
3. Break (failure scenarios)
4. Log (progress)
5. Evaluate (skills matrix)
6. Improve (agent adjusts roadmap)

---

# ✅ Success Criteria

You are progressing if you can:

- Design production-ready systems
- Debug without guidance
- Explain WHY things fail
- Extend basic examples into real-world setups

---

# 🔥 Final Rule

This system only works if:

- You log consistently
- You challenge the agent
- You go beyond tutorials

👉 Copilot is your coach  
👉 You are the engineer doing the work