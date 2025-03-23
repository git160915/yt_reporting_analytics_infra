# Youtube Reporting Analytics Infra repo

my-infra-repo/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── infra/
│   ├── modules/
│   │   ├── state/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── vpc/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── security/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ssm/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ec2/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── responsible/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── envs/
│       ├── dev/
│       │   ├── terragrunt.hcl
│       │   └── components/
│       │       ├── vpc/
│       │       │   └── terragrunt.hcl
│       │       ├── security/
│       │       │   └── terragrunt.hcl
│       │       ├── ssm/
│       │       │   └── terragrunt.hcl
│       │       ├── ec2/
│       │       │   └── terragrunt.hcl
│       │       └── responsible/
│       │           └── terragrunt.hcl
│       ├── integration/
│       │   ├── terragrunt.hcl
│       │   └── components/
│       │       ├── vpc/
│       │       │   └── terragrunt.hcl
│       │       ├── security/
│       │       │   └── terragrunt.hcl
│       │       ├── ssm/
│       │       │   └── terragrunt.hcl
│       │       ├── ec2/
│       │       │   └── terragrunt.hcl
│       │       └── responsible/
│       │           └── terragrunt.hcl
│       └── prod/
│           ├── terragrunt.hcl
│           └── components/
│               ├── vpc/
│               │   └── terragrunt.hcl
│               ├── security/
│               │   └── terragrunt.hcl
│               ├── ssm/
│               │   └── terragrunt.hcl
│               ├── ec2/
│               │   └── terragrunt.hcl
│               └── responsible/
│                   └── terragrunt.hcl
└── README.md

Note: In this approach, every branch (for example, main) contains all the folders (dev, integration, prod). The CI/CD workflow selects which one to deploy based on the branch name. For example, if you push to the dev branch, the workflow will deploy using the configuration in infra/envs/dev.