# Working notes (you write these)

This folder is empty on purpose. Interviewers trust a repo more when they can
see *you* diagnosed a failure, not just that a tutorial passed.

Create files here as you go:

| File | When |
| --- | --- |
| `day1-break-it.md` | After you scale `cartservice` to zero. Record the exact frontend error, the log line, and how frontend finds cartservice (DNS + env var). |
| `day2-helm-ci.md` | Why you templated services as a values loop, why images are tagged with the git SHA, and the red build you caused on purpose. |
| `day3-terraform.md` | What `terraform.tfstate` contained after the first apply, and the public IP screenshot caption. |
| `day4-gitops-obs.md` | The replica-count commit ArgoCD synced, the PromQL that showed load, and the alert you fired. |

Keep them short and in your own words. Those notes become the README's
"Design decisions" and "What I learned" sections on Day 4.
