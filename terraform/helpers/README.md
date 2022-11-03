
## Terraform管理外で手動で行うこと
- Analytics Hub
- Servicesの有効化
- Terraform実行用の環境
  - Terraform用サービスアカウント
  - Cloud BuildのGitHubリポジトリbqfun/jpdata接続
  - Cloud Buildトリガーの作成
  - Terraform用Cloud Storageバケットjpdata-tfstateの作成
- Logging
  - Slackアラート設定
  - アラート設定
- Dataform
  - Cloud BuildのGitHubリポジトリbqfun/jpdata-dataform接続
  - リポジトリ作成
  - ソース接続用のSecret作成
  - ソースGitHubリポジトリ接続
