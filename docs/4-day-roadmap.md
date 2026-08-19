# Online Boutique: 4-day DevOps sprint

Learn by doing. This is the only document you need to go from a cleaned fork to
a live, monitored, GitOps-managed shop on Azure — and to defend it in an
interview.

**Ship in four days. Do not claim mastery.** The sentence you want ready by
Friday is: *"I built this in four days to learn the pipeline end to end, and
here is what I would do differently with more time."* That is credible.
Overclaiming dies in two follow-up questions.

| Day | Theme | You can show |
| --- | --- | --- |
| 1 | Foundations, Codespaces, kind, first deploy, **break it** | Shop in the browser + notes on a dying cart service |
| 2 | Helm you wrote + GitHub Actions you wrote | Chart + green CI publishing images to GHCR |
| 3 | Terraform + AKS | Public IP screenshot (then destroy the cluster) |
| 4 | ArgoCD + Prometheus/Grafana + README | Self-heal demo, dashboards, hire-worthy README |

Hands-on time is ~9 hours a day. Expected Azure spend is **USD 5–15** of the
USD 200 free credit — **if you destroy the cluster at the end of Days 3 and 4**.

Protected blocks (do not skip, even if you cut everything else):

1. Day 1 "break it on purpose"
2. Day 4 README

---

## 0. Where the repo already stands

GCP deploy tooling is already gone (`helm-chart/`, `kustomize/`,
`kubernetes-manifests/`, `istio-manifests/`, `terraform/`, `.deploystack/`,
`cloudbuild.yaml`). This PR also deleted **upstream GitHub Actions** so you
rewrite CI from understanding, not from Google's GCP identity.

**Do not delete**

| Keep | Why |
| --- | --- |
| `src/` | The 11 microservices + loadgenerator |
| `protos/` | gRPC contract every service speaks |
| `skaffold.yaml` | Optional Day 1 evening: build from *your* source |
| `release/kubernetes-manifests.yaml` | Day 1 deploy — Google's prebuilt images, minutes not 45 |

### Tree after this cleanup

```
.
├── .devcontainer/devcontainer.json   # Codespaces environment-as-code
├── .github/workflows/README.md       # empty on purpose — you write ci.yaml on Day 2
├── docs/                             # including this file
├── notes/                            # your diagnosis notes (interview gold)
├── protos/                           # demo.proto — the gRPC contract
├── release/kubernetes-manifests.yaml # keep for Day 1 only
├── src/                              # frontend, cart, catalog, … loadgenerator
├── skaffold.yaml                     # still points at deleted kubernetes-manifests/
└── README.md
```

`skaffold.yaml` still references `kubernetes-manifests/` which we deleted. That
is intentional. Day 1 uses the **release** manifest. If you reach the optional
"build from source" block, you will point Skaffold at a path you recreate.

You will add, by Friday:

```
charts/boutique/          # Day 2 Helm
.github/workflows/ci.yaml # Day 2 CI
infra/                    # Day 3 Terraform
gitops/                   # Day 4 ArgoCD Application
monitoring/               # Day 4 alerts / Grafana extras
```

### Budget and quota (read before Day 1)

| Resource | Free allowance | This sprint | Risk |
| --- | --- | --- | --- |
| GitHub Codespaces | 120 core-hours / month | ~64 on 2-core × 32 h | Safe if you **Stop** when idle |
| GitHub Actions | 2,000 minutes / month | ~100–200 | Safe |
| GHCR | Free for public repos | 11 images × SHA tags | Keep the repo **public** |
| Azure AKS nodes | USD 200 / 30 days | ~USD 5–15 | Only if you forget `terraform destroy` |
| AKS control plane | Always free | USD 0 | None |

Pick the **2-core / 8 GB** Codespace, never the 4-core. 4-core burns hours
twice as fast. Codespaces auto-stops after 30 idle minutes; still stop it
yourself at every break.

---

## How to use this file

Each step is: **Do this** → **Watch for** → **Why / interview**. Tick the
checkboxes in GitHub as you go. After any failure, write 5–10 lines in
[`notes/`](../notes/README.md) *before* you Google. That is the interview
habit.

If you fall behind, cut in this order: load-generator alerting → custom Grafana
dashboard (bundled ones are fine) → ArgoCD self-heal experiments. Never cut
Day 1's break-it block or Day 4's README.

---

## Codespaces setup (do this once, start of Day 1)

Your laptop RAM is not the constraint. A Codespace is an 8 GB Linux VM with
Docker. This repo's [`.devcontainer/devcontainer.json`](../.devcontainer/devcontainer.json)
declares Docker-in-Docker, kubectl, Helm, kind, Terraform, and Azure CLI so you
do **not** hand-install tools and forget what you did.

**Interview line:** "Environments are code, not a wiki of apt-get commands."

### 1. Push this branch so GitHub can see the devcontainer

Codespaces boots from GitHub, not from files only on your laptop.

```sh
git push -u origin HEAD
```

### 2. Create the Codespace

1. Open the repo on GitHub: `https://github.com/Faizan1637/online-boutique-devops`
2. **Code** → **Codespaces** → **New with options** (the `...` menu), not the
   one-click default.
3. Branch: this sprint branch (or `main` after merge).
4. Machine: **2-core, 8 GB RAM**. Confirm it is not 4-core.
5. Region: closest to you.
6. Create.

First boot takes several minutes while features install. Subsequent starts are
faster.

### 3. Confirm the toolchain

In the Codespace terminal:

```sh
docker run hello-world
kubectl version --client
helm version
kind version
terraform version
az version --query '"azure-cli"' -o tsv
```

`hello-world` proves Docker-in-Docker works. Without that, kind cannot create a
cluster.

### 4. Learn to stop it

GitHub → repo → **Code** → **Codespaces** → **Stop**.
Or Command Palette: **Codespaces: Stop Current Codespace**.

Leaving it running overnight is how people blow the 120 core-hour quota.

### What each field in `devcontainer.json` is for

Read the file. You should be able to explain:

| Field | Meaning |
| --- | --- |
| `image` | Base Ubuntu. Features layer tools on top. |
| `docker-in-docker` | A Docker daemon *inside* the Codespace, which kind uses to run Kubernetes nodes as containers. |
| `kubectl-helm-minikube` | kubectl + Helm + **kind** (`minikube: none` — kind is more reliable in Codespaces). |
| `terraform` / `azure-cli` | Day 3. Installing them now means you do not fight tooling on the cloud day. |
| `hostRequirements` | Tells GitHub you need 8 GB. |
| `forwardPorts: [8080]` | After `kubectl port-forward`, Codespaces pops a browser URL. |
| `postCreateCommand` | Prints tool versions so a broken feature is obvious on first boot. |

Rebuild later with Command Palette → **Codespaces: Rebuild Container** if you
edit this file.

---

# Day 1 — Foundations and first deploy (~9 h)

**Goal:** storefront open in the browser on a cluster *you* created, then
deliberately break it.

**Deliverable:** this repo pushed, plus `notes/day1-break-it.md`.

## Block A — Confirm the repo is yours (15 min)

You already own `Faizan1637/online-boutique-devops`. Keep Google's clone as
`upstream` so you can pull source fixes without taking their GCP tooling back.

```sh
git remote -v
# If you only have origin pointing at your fork, add Google as upstream:
git remote add upstream https://github.com/GoogleCloudPlatform/microservices-demo.git
git fetch upstream
```

**Interview:** hiring managers read `git log`. A first commit that says *why*
GCP tooling was removed reads as intent, not a blind fork.

- [ ] `git remote -v` shows `origin` = your fork, `upstream` = Google
- [ ] You can explain why origin and upstream are different remotes

## Block B — Docker fundamentals (1.5 h)

You cannot debug Kubernetes if containers are still magic.

### Read the frontend Dockerfile out loud

Open [`src/frontend/Dockerfile`](../src/frontend/Dockerfile).

1. **Stage `builder`:** `golang:…-alpine`, `go mod download`, then `go build`.
   The compiler and source are in this stage only.
2. **Stage final:** `gcr.io/distroless/static` — no shell, no package manager.
   Only the binary + `templates/` + `static/`.
3. That is a **multi-stage build**: small attack surface, small image, no Go
   toolchain in production.

**Interview:** "Why distroless?" — smaller image, no shell for an attacker,
you debug with `kubectl logs` not `kubectl exec bash` in the frontend.

### Build one image by hand

```sh
docker build -t my-frontend ./src/frontend
docker image history my-frontend
docker run --rm -p 8080:8080 my-frontend
```

**Watch for:** the process **exits**. Frontend calls `mustMapEnv` for every
`*_SERVICE_ADDR` (see `src/frontend/main.go`). No catalog, currency, cart, …
addresses → it refuses to start. This is a *feature*: fail fast instead of
serving a half-wired shop.

- [ ] You explained the two stages in the Dockerfile
- [ ] `docker run` failed and you read the missing-env error
- [ ] `docker image history` showed the distroless final layer is tiny vs builder

## Block C — kind cluster (30 min)

**kind** = Kubernetes IN Docker. A real control plane + worker, as containers.

```sh
kind create cluster --name boutique
kubectl cluster-info
kubectl get nodes
```

**Watch for:** `Ready`. If not, `kubectl describe node` — usually disk or the
Docker-in-Docker daemon is unhappy; rebuild the Codespace rather than fighting
minikube.

Vocabulary you must own (use *your* `kubectl get` output):

| Word | What it is |
| --- | --- |
| Cluster | Control plane + nodes |
| Node | A VM (here: a Docker container) that runs pods |
| Pod | Smallest deployable unit — 1+ containers sharing network/disk |
| Deployment | Controller that keeps N replica pods alive |
| Service | Stable DNS name + virtual IP in front of changing pods |

- [ ] `kubectl get nodes` shows `Ready`
- [ ] You can point at the output and name control plane vs node

## Block D — Deploy the shop (1 h)

Use the **release** manifest. It points at Google's public images
(`us-central1-docker.pkg.dev/online-boutique-ci/microservices-demo/…:v0.10.6`).
Deploy is minutes. Building all 11 services from source is 30–45 minutes and
teaches nothing you will not learn better on Day 2.

```sh
kubectl apply -f release/kubernetes-manifests.yaml
kubectl get pods -w
# Ctrl+C when everything is Running (or CrashLoop — then describe it)
```

You should see ~12 pods: 11 app/data + loadgenerator.

**Spare your 2 CPUs immediately:**

```sh
kubectl scale deploy/loadgenerator --replicas=0
```

**Open the shop:**

```sh
kubectl port-forward deploy/frontend 8080:8080
```

Codespaces will notify you of the forwarded URL (port 8080 is declared in the
devcontainer). Add something to the cart. Checkout. Screenshot it.

On kind there is **no cloud LoadBalancer**. `frontend-external` will stay
`<pending>`. That is expected. Port-forward is the right tool locally.
On Day 3, AKS will allocate a real public IP.

- [ ] All app pods Running (loadgenerator at 0 replicas)
- [ ] Checkout succeeded; screenshot saved

## Block E — Break it on purpose (2.5 h) — highest value of the week

Anyone can paste `kubectl apply`. Interviews ask *what happens when cart
dies*.

The four commands you will use for the rest of your career: **get, describe,
logs, exec**.

### E1. Delete a pod — watch the Deployment resurrect it

```sh
kubectl get pods -l app=frontend
kubectl delete pod <frontend-pod-name>
kubectl get pods -l app=frontend -w
```

**Watch for:** a *new* pod name, `Running` again. You killed a Pod, not the
Deployment. The ReplicaSet creates a replacement. **Self-healing of pods is
Kubernetes. Self-healing of *desired spec vs Git* is ArgoCD (Day 4).** Do not
confuse those in an interview.

### E2. Scale cartservice to zero

```sh
kubectl scale deploy/cartservice --replicas=0
kubectl get pods -l app=cartservice
```

Browse, add to cart.

**Watch for:** the HTTP page that errors. Then:

```sh
kubectl logs -f deploy/frontend
```

Write down the **exact** log line (connection refused / unavailable). That
sentence is your "cartservice dies at 2am" answer's first half.

### E3. Describe and env

```sh
kubectl get pods
kubectl describe pod <any-frontend-pod>
kubectl exec deploy/frontend -- printenv | grep SERVICE_ADDR
```

**Watch for:** `CART_SERVICE_ADDR=cartservice:7070`.

How frontend finds cartservice (memorize this):

1. Manifest sets env `CART_SERVICE_ADDR=cartservice:7070`
2. `cartservice` is a **ClusterIP Service**
3. CoreDNS resolves it to `cartservice.default.svc.cluster.local`
4. kube-proxy / IPVS load-balances to pods with `app=cartservice`
5. Frontend opens a **long-lived gRPC client** at process start — it does not
   re-resolve on every click

### E4. Exec into Redis

```sh
kubectl exec -it deploy/redis-cart -- redis-cli
# KEYS *
# GET <some-key>
```

Cart payload is protobuf bytes keyed by session UUID, not JSON. Empty-dir
volume: **restart Redis, carts vanish**. Interviewers like that honesty.

### E5. Restore and write notes

```sh
kubectl scale deploy/cartservice --replicas=1
```

Write [`notes/day1-break-it.md`](../notes/README.md) in your own words:
frontend error, log line, DNS+env, Redis keys, what Kubernetes restarted vs
what stayed dead.

- [ ] Deleted pod came back with a new name
- [ ] Cart scaled to 0; you captured frontend failure + logs
- [ ] You explained DNS + env without looking it up
- [ ] `notes/day1-break-it.md` exists

## Block F — Optional: build from your source (45 min)

Only if Block E is done. Restore a path Skaffold can apply, or skip Skaffold
and `docker build` + retag. Change visible text in
`src/frontend/templates/` and prove *your* code is what the browser renders.

Do not spend Day 1 here if Block E is thin.

---

# Day 2 — Package it and automate it (~9 h)

**Goal:** replace the Helm chart we deleted with one **you** wrote, then a CI
pipeline that builds and publishes images on every push.

**Deliverable:** `charts/boutique` working on kind, `.github/workflows/ci.yaml`
green, images in GHCR.

## Block A — Feel the YAML pain (1 h)

Open `release/kubernetes-manifests.yaml`. Imagine changing the image tag on
every service, or deploying a staging copy with different replica counts.

That pain is why Helm exists: **chart** (templates) + **values** (config) +
**release** (an installed instance with history).

Optional: `helm repo add bitnami https://charts.bitnami.com/bitnami && helm install demo-redis bitnami/redis` then `helm uninstall demo-redis` so you have
seen a release before you write one.

- [ ] You can define chart, values, release in one sentence each

## Block B — Write the chart (3 h)

Do **not** restore Google's `helm-chart/`. Writing three services properly
teaches templating; the rest is a loop.

```sh
mkdir -p charts
helm create charts/boutique
```

Delete the nginx boilerplate under `templates/` (the sample Deployment,
Service, ingress, HPA, tests). Start clean. Keep `Chart.yaml`, `_helpers.tpl`
(edit it), and `values.yaml` (replace it).

**Suggested `values.yaml` shape** (you type this — adjust ports from the
release manifest):

```yaml
image:
  registry: us-central1-docker.pkg.dev/online-boutique-ci/microservices-demo
  tag: v0.10.6   # later: git SHA from CI
  pullPolicy: IfNotPresent

services:
  frontend:
    replicas: 1
    port: 8080
    type: ClusterIP   # LoadBalancer only on AKS (Day 3)
  cartservice:
    replicas: 1
    port: 7070
  productcatalogservice:
    replicas: 1
    port: 3550
  # … remaining services from the release manifest
  redis-cart:
    replicas: 1
    port: 6379
    image: redis:alpine   # not in the Google registry
  loadgenerator:
    replicas: 0           # keep 0 on 2-CPU clusters

env:
  # frontend mustMapEnv — Service DNS names
  CART_SERVICE_ADDR: "cartservice:7070"
  PRODUCT_CATALOG_SERVICE_ADDR: "productcatalogservice:3550"
  # … copy the rest from release/kubernetes-manifests.yaml frontend env
```

**Templates to write**

1. `_helpers.tpl` — `app.kubernetes.io/name`, `instance`, `managed-by` labels.
   Repeat labels = missed selectors later.
2. One **generic** `templates/workload.yaml` that `range`s `.Values.services`
   and emits Deployment + Service. Special-case Redis (different image, no
   SERVICE_ADDR) and frontend (extra env, HTTP probes on `/_healthz`).
3. If a range feels too abstract at first: template **frontend, cartservice,
   redis-cart by hand**, then refactor into a loop. Interviewers prefer a loop
   you can explain over 11 copy-pasted files you cannot.

Render before you install:

```sh
helm template boutique charts/boutique | less
```

Read the YAML. Check Service names match `*_SERVICE_ADDR`. Check label
selectors match pod labels. A typo here is a Pending/CrashLoop tomorrow.

- [ ] `helm template` output looks like real Deployments/Services
- [ ] Frontend env still matches Service DNS names
- [ ] Labels come from `_helpers.tpl`

## Block C — Deploy the chart (2 h)

```sh
kubectl delete -f release/kubernetes-manifests.yaml
helm install boutique charts/boutique
kubectl get pods
kubectl port-forward svc/frontend 8080:8080
```

Shop still works? Practise rollback so you know it exists:

```sh
helm history boutique
# make a values change, helm upgrade boutique charts/boutique
helm rollback boutique 1
```

- [ ] Chart install serves the shop
- [ ] You rolled back once on purpose

## Block D — Rewrite GitHub Actions (2.5 h)

Upstream workflows are gone. They used Google Workload Identity and trees we
deleted. You will write a pipeline that:

1. Runs **lint/tests before** image builds (fail fast, cheaper).
2. Builds **all services in parallel** (`strategy.matrix`).
3. Pushes to **GHCR** with `GITHUB_TOKEN` (no long-lived secret).
4. Tags images with the **git SHA, never `:latest`**.

Create `.github/workflows/ci.yaml`. Type it. Understand every key.

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read
  packages: write   # GHCR push

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.26"
      - name: Go unit tests
        run: |
          for svc in shippingservice productcatalogservice; do
            (cd src/$svc && go test ./...)
          done
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: "8.0"
      - name: cartservice tests
        run: dotnet test src/cartservice/

  build:
    needs: test
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        service:
          - frontend
          - cartservice
          - productcatalogservice
          - currencyservice
          - paymentservice
          - shippingservice
          - emailservice
          - checkoutservice
          - recommendationservice
          - adservice
          - loadgenerator
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: src/${{ matrix.service }}
          # cartservice Dockerfile lives in src/cartservice/src — fix the context
          push: ${{ github.event_name != 'pull_request' }}
          tags: ghcr.io/${{ github.repository }}/${{ matrix.service }}:${{ github.sha }}
```

**Fixups you must handle yourself (this is the learning):**

- `cartservice` context is `src/cartservice/src`, not `src/cartservice`.
- PRs should **build** but you may skip **push** (fork PRs cannot always write
  packages). `push: ${{ github.event_name != 'pull_request' }}` is a start.
- Package visibility: GitHub → **Packages** → each image → **Public** if the
  repo is public, or AKS cannot pull without an imagePullSecret.
- **Why not `:latest`:** it is a moving pointer. A rollback, a node pull, or a
  debug session cannot say *which git commit* is running. SHA is immutable.
  `:latest` also breaks `imagePullPolicy: IfNotPresent` (nodes keep a stale
  "latest").

**Break the build on purpose.** Introduce a syntax error, push, watch the
check go red, revert. Screenshots of red then green belong in the README.

Then point Helm values at GHCR and `helm upgrade`:

```yaml
image:
  registry: ghcr.io/faizan1637/online-boutique-devops
  tag: "<the sha you just published>"
```

- [ ] `test` job runs before `build`
- [ ] Matrix builds 11 services
- [ ] Images tagged with SHA in GHCR
- [ ] You caused a red build and fixed it
- [ ] Helm now pulls *your* images

---

# Day 3 — Real cloud infrastructure (~9 h)

**Goal:** AKS from Terraform you wrote, shop on a public IP, then destroy it.

**Deliverable:** `infra/` in git, screenshot of the phone-open URL, empty Azure
portal at the end of the day.

**This is the only day that costs money.** Budget alert **before** `apply`.

## Block A — Account and cost (1 h)

1. Azure free account (USD 200 / 30 days).
2. Cost Management → Budgets → **USD 20** alert.
3. In the Codespace:

```sh
az login --use-device-code
az account show
```

Plan: **2 × Standard_B2s** is roughly USD 0.10/hour total. Eight hours ≈ USD 1
for the nodes, plus a little for ACR and the load balancer IP. Forgotten
clusters, not the lab itself, are what get expensive.

- [ ] Budget alert set
- [ ] `az account show` works

## Block B — Terraform fundamentals (2 h)

Four words: **provider, resource, state, plan**.

| Word | Meaning |
| --- | --- |
| Provider | Plugin that talks to an API (`azurerm`) |
| Resource | One object you declare (`azurerm_resource_group`) |
| State | Terraform's memory of what it created (`terraform.tfstate`) |
| Plan | Diff: what *would* change if you apply |

Scratch directory first (throw away):

```hcl
# versions.tf — required_providers azurerm, terraform {}
# main.tf    — provider "azurerm" { features {} }
#            — resource "azurerm_resource_group" "lab" { name = … location = … }
```

```sh
terraform init
terraform plan
terraform apply
# open terraform.tfstate and read it
# change the RG name or a tag, plan again, read the diff
terraform destroy
terraform apply   # feel that "recreate from code" loop
```

**State must never be committed.** It can contain secrets and it is the lock
on reality. Two people applying without shared state = drift and duplicate
resources. `.gitignore` already has `*.tfstate*`. Later (production) you would
use a remote backend (Azure Storage) with locking. For this sprint, local
state in the Codespace is OK **if you never commit it** and you `destroy`
before deleting the Codespace.

**Interview:** "What is Terraform state?" — JSON mapping of addresses to real
IDs. Without it Terraform cannot know what to update vs recreate. Git is not
a backend: no locking, leaked secrets, and `git clone` on a laptop is not the
cluster's source of truth.

- [ ] You read `terraform.tfstate` once
- [ ] You ran plan after a change and explained the diff
- [ ] Destroy then recreate worked

## Block C — AKS from scratch (3 h)

`infra/` with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`. **No
copy-paste of a giant community module** — you must explain every resource.

Minimum set:

1. `azurerm_resource_group`
2. `azurerm_virtual_network` + `azurerm_subnet` (AKS needs its own subnet)
3. `azurerm_kubernetes_cluster`
   - `default_node_pool`: 2 × `Standard_B2s`, `os_disk_size_gb` modest
   - `identity { type = "SystemAssigned" }`
4. `azurerm_container_registry` (`sku = "Basic"`)
5. `azurerm_role_assignment` — AKS kubelet identity `AcrPull` on the ACR
6. Outputs: `kube_config` **marked `sensitive = true`**, ACR login server,
   resource group name, cluster name

```sh
cd infra
terraform init
terraform plan -out=tfplan
# read every line of the plan
terraform apply tfplan
```

Apply takes 5–10 minutes. Stay until it finishes.

- [ ] Plan read before apply
- [ ] Cluster shows in `az aks list`
- [ ] ACR pull role is assigned

## Block D — Ship to the cloud (1.5 h)

```sh
az aks get-credentials --name <cluster> --resource-group <rg>
kubectl config get-contexts
# confirm you are NOT on kind-boutique
helm upgrade --install boutique ../charts/boutique \
  --set services.frontend.type=LoadBalancer
kubectl get svc frontend -w
```

Wait for `EXTERNAL-IP`. Open it on your **phone**. Screenshot — portfolio hero
image. If it stays pending > 5 minutes: `kubectl describe svc frontend` (quota,
region, or the AKS outbound IP).

- [ ] Context is AKS, not kind
- [ ] Public IP works on a phone
- [ ] Screenshot saved

## Block E — Tear down (30 min)

```sh
# screenshots + helm status + terraform output (no secrets in git)
terraform destroy
```

Azure Portal → Resource groups: **empty**. A leftover RG is still billing.

- [ ] Portal shows nothing boutique-related
- [ ] Notes include the public IP screenshot caption

---

# Day 4 — GitOps, observability, portfolio (~9 h)

**Goal:** cluster pulls from Git, you have metrics, README a hiring manager
finishes.

**Deliverable:** ArgoCD Application, kube-prometheus-stack, README, then
`terraform destroy` again.

## Block A — GitOps with ArgoCD (2.5 h)

Until now you **pushed** into the cluster (`kubectl`, `helm`). GitOps
**inverts** that: the cluster **pulls** the desired spec from Git and
corrects drift.

```sh
cd infra && terraform apply
az aks get-credentials --name <cluster> --resource-group <rg>

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get pods
# port-forward the argocd-server Service; login; get the initial admin secret
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Write `gitops/application.yaml` **in this repo** (the whole point is Git):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: boutique
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Faizan1637/online-boutique-devops.git
    targetRevision: main
    path: charts/boutique
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: boutique
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

`kubectl apply -f gitops/application.yaml`. Wait until Synced/Healthy.

Then: change `replicas` in `values.yaml`, **commit and push**, do **not** run
helm. Watch ArgoCD sync. Then: `kubectl delete deploy frontend -n boutique`
and watch ArgoCD recreate it. That is self-heal.

**Interview:** "What does ArgoCD give you that `kubectl apply` in CI does
not?" — CI apply is fire-and-forget; the cluster can drift and CI will not
notice until the next push. ArgoCD continuously compares Git vs live, can
prune extras, and heals manual kubectl. Git is the desired state; the cluster
is not.

- [ ] Application Synced from Git
- [ ] Replica change via git only
- [ ] Deleted Deployment came back

## Block B — Prometheus and Grafana (3 h)

"I would check the logs" is a junior incident answer. Metrics + dashboards +
alerts is the senior one.

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

Port-forward Prometheus (`svc/kps-kube-prometheus-stack-prometheus`) and Grafana
(`svc/kps-grafana`). Grafana admin password is in a Secret — `kubectl get
secret` in `monitoring`.

**Four PromQL building blocks** (run them by hand):

| Piece | Meaning | Try |
| --- | --- | --- |
| Counter | Only goes up (requests, restarts) | `kube_pod_container_status_restarts_total` |
| Gauge | Can go up or down (CPU, memory) | `container_memory_working_set_bytes` |
| `rate()` | Per-second increase of a counter | `rate(container_cpu_usage_seconds_total[5m])` |
| `histogram_quantile()` | Latency percentiles from histogram buckets | skip if no app histograms yet |

Explore bundled dashboards (Kubernetes / Compute Resources / Namespace). Then
**one dashboard of your own:** pod restarts, CPU, memory — grouped by
`label_app` or namespace `boutique`.

```sh
kubectl scale deploy/loadgenerator -n boutique --replicas=1
```

Watch graphs move. Screenshot under load.

Write **one** alert, e.g. crash-loop. Put it in `monitoring/alerts.yaml` as a
`PrometheusRule` (the stack's operator picks those up), or a Helm values extra
rule. Trigger it: `kubectl delete pod` in a tight loop or a bogus image tag.
Screenshot the firing alert. Scale loadgenerator back to 0 when done.

- [ ] PromQL: rate of CPU or restarts run by hand
- [ ] Custom dashboard screenshot
- [ ] One alert fired on purpose

## Block C — Make it hire-worthy (2.5 h)

This block converts four days into interviews. Do it while you still have the
cluster for screenshots, then destroy.

README structure (rewrite the root `README.md`):

1. **What it is** — one paragraph. Not Google's demo pitch.
2. **Architecture diagram** — CI → GHCR → Terraform/AKS → ArgoCD →
   Prometheus/Grafana. Mermaid is enough if you cannot draw.
3. **Screenshots** — public IP shop + Grafana under load.
4. **How to run** — Codespaces, kind path, Terraform path, **destroy**.
5. **Design decisions and trade-offs** — kind vs minikube, SHA vs latest,
   Helm loop vs 11 files, local Terraform state vs remote backend, LoadBalancer
   on frontend only.
6. **Known limitations and next steps** — honesty reads as seniority. Examples:
   no network policies, Redis emptyDir, no HPA, local Terraform state, AKS is
   destroyed after the lab, shopping assistant not in the default path.
7. Green CI badge (your workflow, not Google's). Repo **public**.

Then:

```sh
cd infra && terraform destroy
# Portal: nothing billing
```

- [ ] README a stranger can finish
- [ ] Design decisions + limitations sections exist
- [ ] CI badge is yours and green
- [ ] Azure spend is ~zero

---

## Interview exit exam

If you cannot answer these from memory, go back to the day in parentheses.
Treat this as the bar, not a script to recite.

1. **Walk me through Add to Cart.** (Day 1, plus `docs/storefront-breakdown.md`
   if that PR is merged.) Browser HTTP → frontend → gRPC `AddItem` on
   cartservice → Redis. Session cookie is the cart key.
2. **cartservice dies at 2am. How do you find out, and what do you do?**
   (Days 1 + 4.) Alert on crash-loop / error rate → Grafana/Prometheus →
   `kubectl logs` / `describe` → if replicas 0 or image bad, Git/ArgoCD is the
   fix, not a snowflake kubectl on prod. Kubernetes will restart a crashed
   *pod*; it will not restore a Deployment you scaled to zero unless GitOps
   self-heal is on.
3. **Why SHA tags not `:latest`?** (Day 2.) Immutability, rollback, audit,
   `IfNotPresent` correctness.
4. **What is Terraform state, and why not Git?** (Day 3.) Mapping + possible
   secrets + locking. Git has none of the last two and is a leak.
5. **ArgoCD vs kubectl apply in CI?** (Day 4.) Continuous reconcile vs
   one-shot. Drift, prune, self-heal.
6. **Pod stuck Pending.** (Day 1.) `kubectl describe pod` → Events. Usual:
   insufficient CPU/memory, PVC unbound, `imagePullBackOff` is actually a
   different phase (Waiting), node taints, missing ServiceAccount.
7. **Why is frontend a LoadBalancer and backends ClusterIP?** (Days 1 + 3.)
   Only the HTTP BFF must be reachable from the internet. Backends stay on the
   cluster network. Smaller attack surface, no public gRPC.
8. **What would you change before real customers?** (Day 4 limitations.) TLS
   on the edge, authn, network policies, Redis persistence or managed Redis,
   remote Terraform state + CI plan, HPA, resource requests/limits from load
   tests, no loadgenerator in prod, image scanning, secrets not in values.yaml.

---

## Command cheat sheet

```sh
# cluster
kind create cluster --name boutique
kubectl get nodes,pods,svc -A
kubectl describe pod <pod>
kubectl logs -f deploy/frontend
kubectl exec -it deploy/redis-cart -- redis-cli
kubectl scale deploy/loadgenerator --replicas=0
kubectl port-forward deploy/frontend 8080:8080
kubectl config get-contexts

# helm
helm template boutique charts/boutique
helm install boutique charts/boutique
helm upgrade boutique charts/boutique
helm rollback boutique 1
helm history boutique

# terraform
terraform init && terraform plan -out=tfplan && terraform apply tfplan
terraform destroy

# azure
az login --use-device-code
az aks get-credentials --name <cluster> -g <rg>
```

---

## Honest close

Four days is enough to **build** this and **defend the core flow**. It is not
enough to master Kubernetes, Terraform, and GitOps. Nobody does that in four
days. Ship the artifact, then keep deepening it. That story is both true and
impressive.
