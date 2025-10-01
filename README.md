Infra / Terraform — módulos iniciais

Objetivo
- Estruturar um repositório/dir de Infra com módulos Terraform mínimos para provisionar na AWS os recursos usados no Tech Challenge: rede (VPC/NLB), EKS, RDS, Lambda, API Gateway, IAM, ECR.

Estrutura sugerida (criadas aqui como esqueleto):

infra/
  main.tf            # entrypoint que instancia módulos (envs/overrides)
  variables.tf
  outputs.tf
  README.md
  modules/
    network/
    iam/
    eks/
    rds/
    lambda/
    api_gateway/

Como usar
1. Configure provider AWS (credentials, region) via env vars or profile.
2. Ajuste variáveis em `terraform.tfvars` ou use -var flags.
3. terraform init && terraform plan && terraform apply

Boas práticas
- Usar remote state (S3 + DynamoDB lock) em production.
- Separar workspaces por ambiente (dev/stage/prod).
- Nunca commitar secrets; use AWS Secrets Manager e GitHub Secrets para pipelines.

Próximo passo
- Preencher cada módulo com recursos específicos e políticas de IAM mínimas.
- Integrar pipelines (GitHub Actions) que executem terraform fmt/validate/plan/apply com approvals.
