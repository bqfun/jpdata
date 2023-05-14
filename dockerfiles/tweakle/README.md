# tweakle
Extract/Transform/Load処理を行うCloud Runの実装。
BigQueryからリモート関数として呼ばれることを想定する。

特に以下のことを行う。
- Extract: HTTPリクエスト
- Transform: 単純な加工（tweak）
- Load: Cloud Storageへのアップロード

## ビルド方法
buildpacksを用いてビルドする。

```shell
pack build tweakle --builder gcr.io/buildpacks/builder
```

## 使い方

### デプロイ

```shell
gcloud builds submit --project your-project --pack image=gcr.io/jpdata/github.com/bqfun/tweakle
gcloud run deploy --project your-project --image=gcr.io/jpdata/github.com/bqfun/tweakle --platform managed
bq mk --connection --location=US --project_id=your-project --connection_type=CLOUD_RESOURCE tweakle
```

### 関数呼び出し

```bigquery
CREATE OR REPLACE FUNCTION your_dataset.tweakle(method STRING, url STRING, body STRING, isZip BOOL, charset STRING, bucket STRING, object STRING) RETURNS JSON
REMOTE WITH CONNECTION `your-project.US.tweakle`
OPTIONS (
    endpoint = 'https://<cloud run url>'
);

SELECT your_dataset.tweakle(
    method  => "POST",
    url     => "https://info.gbiz.go.jp/hojin/Download",
    body    => "downfile=13&downtype=csv&downenc=UTF-8",
    isZip   => false,
    charset => "utf-8",
    bucket  => "http-bq-gbizinfo",
    object  => "finance.csv"
);
```