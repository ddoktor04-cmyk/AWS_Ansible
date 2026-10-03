# CMD521 — Terraform + Ansible lab (AWS_Ansible)

Terraform provisions **two EC2 instances** (Ubuntu + Amazon Linux) in one AWS
region, they are registered in a **FastAPI inventory API through its web UI**,
and an **Ansible playbook** configures them by group/role.

| Piece | Where |
|---|---|
| Terraform (2 EC2, key pair, SG) | `main.tf`, `vars.tf`, `ec2.tf`, `outputs.tf` |
| Inventory API + web UI | `api/` (FastAPI + SQLite + Jinja2) |
| Dynamic inventory bridge | `scripts/inventory.py` → `http://localhost:8000` |
| Static inventory (fallback) | `inventory/production/hosts` + `group_vars/` |
| Playbooks & roles | `playbooks/` (`install-packages.yml` + role `common`, `install-windows-packages.yml` + role `windows-common`) |

## Hosts

| Inventory name | OS | User | Group |
|---|---|---|---|
| `ubuntu` | Ubuntu 24.04 LTS | `ubuntu` | `aws_hosts` |
| `amazon-linux` | Amazon Linux 2023 | `ec2-user` | `aws_hosts` |
| `win10` | Windows 10 (Proxmox VM) | `user1` | `windows_hosts` |

## 1. Provision with Terraform

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in AWS keys
terraform init
terraform plan
terraform apply
```

Key outputs: `ubuntu_ip`, `amazon_linux_ip`, `inventory_snippet`,
`private_key_path` (`keys/cmd521-key.pem`, gitignored, mode 0600).

Copy the key to the controller:

```bash
scp -i keys/cmd521-key.pem keys/cmd521-key.pem user1@172.14.50.148:AWS_Ansible/keys/
```

## 2. Run the inventory API (controller)

```bash
git clone https://github.com/ddoktor04-cmyk/AWS_Ansible.git
cd AWS_Ansible
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn api.main:app --host 0.0.0.0 --port 8000
```

Open `http://172.14.50.148:8000/login` → **admin / admin** →
**Groups → Add Group** (`aws_hosts`, `windows_hosts`) →
**Hosts → Add Host** (`ubuntu`, `amazon-linux`, `win10`).

## 3. Run the playbook

```bash
ansible-inventory --graph                     # check groups
ansible aws_hosts -m ping                     # connection test

ansible-playbook playbooks/install-packages.yml
ansible-playbook playbooks/install-packages.yml -e "target_hosts=ubuntu"
ansible-playbook playbooks/install-windows-packages.yml   # choco: Notepad++, Wireshark, Chrome, git, 7-Zip, VS Code
ansible-playbook playbooks/win-config.yml --tags info
```

Static inventory fallback (API not running):

```bash
ansible-playbook playbooks/install-packages.yml -i inventory/production/hosts
```

## Project structure

```
.
├── main.tf / vars.tf / ec2.tf / outputs.tf   # Terraform: 2 EC2 in eu-north-1
├── keys/cmd521-key.pem                       # generated, gitignored
├── api/                                      # FastAPI inventory API + web UI
├── scripts/inventory.py                      # dynamic inventory (calls the API)
├── inventory/production/
│   ├── hosts                                 # static fallback (INI)
│   └── group_vars/{aws_hosts,windows_hosts}.yml
├── playbooks/
│   ├── install-packages.yml                  # hosts: aws_hosts → role common
│   ├── install-windows-packages.yml          # hosts: windows_hosts → role windows-common
│   ├── win-bootstrap.yml / win-config.yml    # Windows
│   ├── roles/common/{defaults,tasks}/main.yml
│   └── roles/windows-common/{defaults,tasks}/main.yml   # Chocolatey
├── ansible.cfg                               # inventory = scripts/inventory.py
├── requirements.txt
└── .opencode/skills/                         # ansible-playbook, ansible-dynamic-inventory
```

## Cost & teardown

Two `t3.micro` instances fit into the 750 h/month free tier — destroy the lab
when you are done:

```bash
terraform destroy
```

## Credits

Inventory API, dynamic inventory script and playbook layout follow the
[macnaer/CMD521-ansible](https://github.com/macnaer/CMD521-ansible) example.
