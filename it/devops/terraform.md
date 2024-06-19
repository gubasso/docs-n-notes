# DevOps: Terraform

## Install

- Install and manage versions with `tfenv`
- or with asdf
  - https://github.com/asdf-community/asdf-hashicorp
  ```
  asdf plugin-add boundary https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add consul https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add levant https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add nomad https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add packer https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add sentinel https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add serf https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add terraform https://github.com/asdf-community/asdf-hashicorp.git
  # language server
  asdf plugin-add terraform-ls https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add tfc-agent https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add vault https://github.com/asdf-community/asdf-hashicorp.git
  asdf plugin-add waypoint https://github.com/asdf-community/asdf-hashicorp.git
  ```

## General

- https://github.com/terraform-docs/terraform-docs
  - https://github.com/looztra/asdf-terraform-docs

- https://github.com/GoogleCloudPlatform/terraformer
  - About: CLI tool to generate terraform files from existing infrastructure (reverse Terraform). Infrastructure to Code
  - https://github.com/gr1m0h/asdf-terraformer

## Conventions

Basic file structure:

- `terraform.tf`
  - profile configuration
  - required_providers
    - packages / dependencies
- `variables.tf`
- `main.tf`
  - resource definitions

*.tfstate stored in S3?


## Resources

- [Terraform has forever changed the way I deploy code - Dreams of Code](https://www.youtube.com/watch?v=cGPyH-PO8vg)
