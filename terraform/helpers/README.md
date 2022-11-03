
# Terraform管理外で手動で行うこと
1. サービスを有効化する
2. Terraform環境を用意する
3. アラートを設定する
4. Dataform環境を用意する
5. Analytics Hub環境を用意する

## サービスを有効化する

```shell
gcloud services enable \
    analyticshub.googleapis.com \
    artifactregistry.googleapis.com \
    batch.googleapis.com \
    bigqueryconnection.googleapis.com \
    cloudbuild.googleapis.com \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    dataform.googleapis.com \
    iam.googleapis.com \
    pubsub.googleapis.com \
    secretmanager.googleapis.com \
    workflowexecutions.googleapis.com \
    workflows.googleapis.com
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
Webからのトリガーの作成はスキップして、Cloud Shellで次のコマンドを入力する。

```shell
gcloud beta builds triggers create github \
    --name=terraform \
    --repo-name=jpdata \
    --repo-owner=bqfun \
    --branch-pattern=^main$ \
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
severity=ERROR resource.type="workflows.googleapis.com/Workflow"
severity=ERROR log_name="projects/jpdata/logs/batch_agent_logs"
```

## Dataform環境を用意する
- Cloud BuildのGitHubリポジトリbqfun/jpdata-dataform接続
- リポジトリ作成
- ソース接続用のSecret作成
- ソースGitHubリポジトリ接続

## Analytics Hub環境を用意する

### エクスチェンジを作成する

https://console.cloud.google.com/bigquery/analytics-hub/exchanges からエクスチェンジを作成する。
リージョン asia-northeast1 、表示名 jpdata 、メインの連絡先 https://bqfun.jp/ 。説明は以下。

```
BigQueryユーザコミュニティBQ Funにて、オープンデータを加工してBigQuery上で公開するエクスチェンジ。
https://bqfun.jp/
```

allAuthenticatedUsers にロール「Analytics Hub サブスクライバー」を付与する。

### リスティングを作成する

リスティング単位のロール付与はしない。

#### gBizINFO preprocessed by BQ FUN
表示名：gBizINFO preprocessed by BQ FUN
メインの連絡先：https://bqfun.jp/
カテゴリ：公共部門

共有データセット：gbizinfo

ドキュメント
```
# 日本の法人情報 gBizINFO preprocessed by BQ FUN
法人番号を持っている組織の情報をまとめたものです。

「gBizINFO」（経済産業省）（https://info.gbiz.go.jp/hojin/DownloadTop ）をもとにBigQueryユーザコミュニティBQ FUNが加工して作成しています。

出典：gBizINFO （METI）経済産業省（https://info.gbiz.go.jp/ ）

BQ FUNは、利用者が本コンテンツを用いて行う一切の責任を負いません。
また、予告なく変更、削除される場合があります。
```

#### JP Holidays preprocessed by BQ FUN

表示名：JP Holidays preprocessed by BQ FUN
メインの連絡先：https://bqfun.jp/
カテゴリ：公共部門

共有データセット：gbizinfo

ドキュメント
```
# 日本の祝日 JP Holidays preprocessed by BQ FUN
国民の祝日情報です。

「国民の祝日について」（内閣府）（https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html ）をもとにBigQueryユーザコミュニティBQ FUNが加工して作成しています。

出典：「国民の祝日について」（内閣府）（https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html ）

BQ FUNは、利用者が本コンテンツを用いて行う一切の責任を負いません。
また、予告なく変更、削除される場合があります。
```