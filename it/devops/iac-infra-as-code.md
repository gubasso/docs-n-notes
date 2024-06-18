# DevOps: IaC - Infra as Code

```
infra/
├── terraform/
│   ├── main.tf
│   ├── vps_template.yaml
│   ├── variables.tf
│   ├── terraform.tfstate
│   └── outputs.tf
└── ansible/
    ├── ansible.cfg
    ├── tf_inventory.py
    ├── playbooks/
    │   ├── site.yml
    │   ├── webserver.yml
    │   └── database.yml
    └── roles/
        ├── common/
        │   ├── tasks/
        │   │   └── main.yml
        │   ├── handlers/
        │   │   └── main.yml
        │   └── templates/
        ├── webserver/
        │   ├── tasks/
        │   │   └── main.yml
        │   ├── handlers/
        │   │   └── main.yml
        │   └── templates/
        └── database/
            ├── tasks/
            │   └── main.yml
            ├── handlers/
            │   └── main.yml
            └── templates/
```
