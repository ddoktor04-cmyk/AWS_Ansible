---
name: ansible-dynamic-inventory
description: FastAPI inventory API + web UI for Ansible (add/edit hosts and groups through a browser) and the scripts/inventory.py dynamic inventory bridge. Use when registering servers in the inventory API or debugging the API-to-Ansible flow.
metadata:
  author: cmd521
  version: "1.0"
---

# Ansible Dynamic Inventory API (FastAPI + Web UI)

Reference example: https://github.com/macnaer/CMD521-ansible

## When to Use

- Registering new servers (EC2, VMs) into the Ansible inventory via browser
- Exposing group/host variables to Ansible through a REST API
- Debugging why `ansible-inventory` sees (or misses) a host

## Architecture

```
browser ──> FastAPI web UI (:8000) ──> SQLite inventory.db
                     │
                     └── GET /api/hosts, /api/groups  <── scripts/inventory.py ──> ansible
```

`ansible.cfg` → `inventory = scripts/inventory.py` (dynamic by default).
`inventory/production/hosts` stays as a static fallback (`-i inventory/production/hosts`).

## Setup & run (controller)

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn api.main:app --host 0.0.0.0 --port 8000
```

Web UI: `http://<controller>:8000/login` — default **admin / admin**.

> Ubuntu 24.04: system pip is locked (PEP 668) — always use a venv.

## Registering a host through the web UI

1. **Groups → Add Group** — e.g. `aws_hosts` with:
   `Become=yes`, `Become Method=sudo`,
   `SSH Key File=/home/user1/AWS_Ansible/keys/cmd521-key.pem`,
   `Python Interpreter=/usr/bin/python3`,
   `SSH Common Args=-o StrictHostKeyChecking=no`
2. **Groups → Add Group** — `windows_hosts` with:
   `Connection=winrm`, `Scheme=http`, `Port=5985`,
   `Transport=basic`, `SSL Validation=ignore`
3. **Hosts → Add Host** — name, group, IP (`ansible_host`), user (`ansible_user`),
   password only for Windows (`ansible_password`).

## API endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET/POST | `/login` | No | Session login |
| GET | `/hosts`, `/hosts/add`, `/hosts/{id}/edit` | Yes | Host CRUD (HTML) |
| GET | `/groups`, `/groups/add`, `/groups/{id}/edit` | Yes | Group CRUD (HTML) |
| GET | `/api/hosts` | No | Flat hosts (group vars merged) — inventory script |
| GET | `/api/groups` | No | Groups + vars — inventory script |

## Verify the flow

```bash
curl -s localhost:8000/api/hosts | jq
scripts/inventory.py --list
ansible-inventory --graph
ansible aws_hosts -m ping
```

## Gotchas

1. API must be running — otherwise `inventory.py` fails and Ansible has no inventory
2. `inventory.py` hardcodes `http://localhost:8000` — change `API_BASE` if the API is remote
3. Group vars from the API win over `inventory/production/group_vars/*` only for the dynamic path
4. Passwords typed into the web UI are stored **plaintext in SQLite** — never commit `inventory.db`
5. Host names must be unique (DB constraint) — reuse Edit instead of adding duplicates
