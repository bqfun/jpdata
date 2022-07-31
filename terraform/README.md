# Terraform
jpdataの構成をTerraformで管理する

## 設定時の注意
backend.tfのbucket、terraform.tfvarsのprojectはベタ書きしてあるため、他環境のApply時に注意すること。

## Terraform管理外のリソース
- Analytics Hub
- Google-managed service accounts
- Servicesの有効化
- Terraform実行用の環境
  - Cloud Buildトリガーterraform
  - Terraform用サービスアカウント
  - Terraform用Cloud Storage bucket