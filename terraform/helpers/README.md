
# Terraform管理外で手動で行うこと
1. サービスを有効化する
2. Terraform環境を用意する
3. アラートを設定する
4. Dataform実行用のシークレットを用意する

## サービスを有効化する

```shell
gcloud services enable \
    cloudbuild.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com
```

## Terraform環境を整備する

### ストレージバケットを作成する

```shell
gcloud storage buckets create gs://jpdata-tfstate
```

### サービスアカウントを作成する

```shell
gcloud iam service-accounts create terraform
```

```shell
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member="serviceAccount:terraform@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role="roles/owner"
```

### ビルドトリガーを作成する
https://console.cloud.google.com/cloud-build/triggers の「リポジトリを接続」から
「ソースを選択」で「GitHub（Cloud Build GitHub アプリ）」を選択後、認証を進める。

「リポジトリを選択」で、GitHub アカウント：bqfun、リポジトリ：bqfun/jpdataを選択する。
Webからのトリガーの作成はスキップし、同様の手順で次のリポジトリを接続する（トリガーはTerraformで作成される）。

- bqfun/jpdata-dataform
- bqfun/bqfunc

Cloud Shellで次のコマンドを入力して、Terraformのトリガーを作成する。

```shell
gcloud beta builds triggers create github \
    --name=terraform \
    --repo-name=jpdata \
    --repo-owner=bqfun \
    --branch-pattern=.* \
    --build-config=terraform/cloudbuild.yaml \
    --included-files=terraform/** \
    --service-account=projects/${GOOGLE_CLOUD_PROJECT}/serviceAccounts/terraform@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
```

## アラートを設定する

### 通知チャネルを作成する
https://console.cloud.google.com/monitoring/alerting/notifications からSlackの通知チャネルを作成する。
チャネル名はSlack BQ FUN jpdata。 BQ FUN Slackワークスペースを認証し、#jpdataチャンネルに通知する。

### アラートポリシーを設定する
以下のようなポリシーを設定し、通知チャネルにSlack BQ FUN jpdataを設定する。

```
Workflow の実行中にエラーが発生しました
severity=ERROR resource.type="workflows.googleapis.com/Workflow"

Batch 実行中にエラーが発生しました
severity=ERROR log_name="projects/jpdata/logs/batch_agent_logs"
```

## Dataformリポジトリ接続用のSecret（github-personal-access-token）に値を設定
https://github.com/settings/tokens からFine-grained tokensを選択し、トークンを生成する。
生成されたトークンをSecret Managerに登録する。
