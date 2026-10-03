---
name: ansible-playbook
description: Ansible playbook standards, roles, inventory groups and run/validate commands. Use when writing or running playbooks, roles, inventories, or troubleshooting Ansible connections (SSH/WinRM).
metadata:
  author: cmd521
  version: "1.0"
---

# Ansible Playbooks & Roles

Reference example: https://github.com/macnaer/CMD521-ansible

## When to Use

- Writing or reviewing playbooks and roles
- Grouping hosts into inventory groups by role/OS
- Running/validating playbooks on the controller
- Debugging SSH or WinRM connectivity

## Inventory groups (this lab)

| Group | Hosts | Users | Connection |
|---|---|---|---|
| `aws_hosts` | `ubuntu`, `amazon-linux` (EC2) | `ubuntu`, `ec2-user` | SSH (key) |
| `windows_hosts` | `win10` | `user1` | WinRM `http:5985`, `basic` |

Group variables live in `inventory/production/group_vars/<group>.yml`
(never put passwords there — API DB or vault only).

## Parameterization (STRICT)

Never hardcode `hosts:` — always use a variable with a default:

```yaml
- name: Install common packages
  hosts: "{{ target_hosts | default('aws_hosts') }}"
  become: yes
  roles:
    - common
```

Users target a single host with `-e`:

```bash
ansible-playbook playbooks/install-packages.yml -e "target_hosts=ubuntu"
```

## Playbook standards

- Use FQCN: `ansible.builtin.*`, `ansible.windows.*`, `community.windows.*`
- `snake_case` for variable names; play names start with an action verb
- Idempotent tasks: always `state: present/absent/started/stopped`
- Prefer `ansible.builtin.package` over distro-specific modules
- `changed_when` / `failed_when` for better reporting; `block/rescue/always` for error handling
- No hardcoded secrets — vault, inventory API, or `-e`

## Role layout

```
playbooks/roles/common/
├── defaults/main.yml   # common_packages (list)
└── tasks/main.yml      # apt cache for Debian + package loop
```

## Windows rules

- `ansible.windows.win_ping` (not `ping`), `win_shell` / `win_command`
- Transport: `winrm` + `basic` + `ansible_winrm_scheme=http` + port `5985`
- `ansible_winrm_server_cert_validation=ignore` for the lab
- Enable WinRM on the target first: `playbooks/winrm-setup.ps1` (admin) or `win-bootstrap.yml`

## Run & validate

```bash
ansible-inventory --graph                      # group tree
ansible-inventory --list                       # full vars (dynamic)
ansible aws_hosts -m ping                      # connection test
ansible windows_hosts -m ansible.windows.win_ping

ansible-playbook playbooks/install-packages.yml --syntax-check
ansible-playbook playbooks/install-packages.yml --check --diff
ansible-playbook playbooks/install-packages.yml -vvv   # debug
ansible-lint playbooks/install-packages.yml
```

## Troubleshooting

1. Connection refused/timeout → check SG (22/tcp), public IP, key path
2. `Decryption failed (no vault secrets...)` → `vault_password_file` in `ansible.cfg` wrong or stale ciphertext
3. WinRM `credentials were rejected` → wrong user/password (passwords are case-sensitive)
4. `Permission denied` → `become: yes` + sudo, or key not accepted by the instance
5. Undefined variable → check group name spelling and group_vars file location
