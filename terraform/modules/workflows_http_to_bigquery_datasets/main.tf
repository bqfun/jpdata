data "google_project" "project" {}

locals {
  main          = "http-bq-${replace(var.name, "_", "-")}"
  us_dataset_id = "US__${var.name}"
}

resource "random_uuid" "main" {}

resource "google_service_account" "main" {
  account_id = substr(local.main, 0, 19)
}

resource "google_storage_bucket" "main" {
  name          = local.main
  location      = "us-west1"
  force_destroy = true
  labels        = var.labels
}

resource "google_storage_bucket_iam_member" "main" {
  bucket = google_storage_bucket.main.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.main.email}"
}

resource "google_cloud_run_service" "main" {
  name     = local.main
  location = "us-west1"

  template {
    spec {
      containers {
        image = var.tweakle_image
        resources {
          limits = {
            # https://cloud.google.com/run/docs/configuring/cpu
            cpu = var.tweakle_cpu
            # https://cloud.google.com/run/docs/configuring/memory-limits
            memory = var.tweakle_memory
          }
        }
      }
      container_concurrency = 1
      service_account_name  = google_service_account.main.email
    }
    metadata {
      labels = var.labels
    }
  }
}

resource "google_cloud_run_service_iam_member" "main" {
  location = google_cloud_run_service.main.location
  service  = google_cloud_run_service.main.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.main.email}"
}

resource "google_bigquery_data_transfer_config" "main" {
  display_name           = "${local.us_dataset_id}-${var.name}"
  location               = "asia-northeast1"
  data_source_id         = "cross_region_copy"
  destination_dataset_id = var.name
  params = {
    source_dataset_id           = local.us_dataset_id
    overwrite_destination_table = true
  }
  schedule_options {
    disable_auto_scheduling = true
  }
  service_account_name = google_service_account.main.email
}

resource "google_project_iam_member" "main" {
  project = data.google_project.project.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.main.email}"
  # To create the copy transfer, you need the following on the project:
  #   - bigquery.transfers.update
  #   - bigquery.jobs.create
  # https://cloud.google.com/bigquery/docs/copying-datasets#required_permissions
}

resource "google_workflows_workflow" "main" {
  name            = local.main
  region          = "us-west1"
  service_account = google_service_account.main.email
  labels          = var.labels
  source_contents = <<-EOT
  main:
    steps:
      - init:
          assign:
            - areAllSkipped: true
      - runAllExtractTweakLoadTransform:
          parallel:
            shared: [areAllSkipped]
            for:
              value: job_args
              in:%{for i, c in var.etlt}
                - body:
                    extraction:
                      url: ${c.extraction.url}
                      method: ${coalesce(c.extraction.method, "GET")}
                      body:
                        ${indent(22, yamlencode(coalesce(c.extraction.body, {})))}
                    tweaks:%{for k, v in c.tweaks}
                      - call: ${v.call}
                        args:
                          ${yamlencode(coalesce(v.args, {}))}%{endfor}
                    loading:
                      bucket: ${google_storage_bucket.main.name}
                      object: ${c.name}
                  query: |-
                    ${indent(18, c.transformation.query)}
                %{endfor}
              steps:
                - callExtractTweakLoadTransform:
                    call: extractTweakLoadTransform
                    args:
                      body: $${job_args.body}
                      query: $${job_args.query}
                    result: isSkipped
                - mergeResponse:
                    assign:
                      - areAllSkipped: $${areAllSkipped and default(isSkipped, false)}
      - skipIfAllNotUpdated:
          switch:
            - condition: $${areAllSkipped}
              return: true
      - transfer:
          call: googleapis.bigquerydatatransfer.v1.projects.locations.transferConfigs.startManualRuns
          args:
            parent: ${google_bigquery_data_transfer_config.main.name}
            body:
              requestedRunTime: $${time.format(sys.now() + 30)}
  extractTweakLoadTransform:
    params: [body, query]
    steps:
      - extractTweakLoadStep:
          call: http.post
          args:
            url: ${google_cloud_run_service.main.status[0].url}
            auth:
              type: OIDC
            body: $${body}
          result: resp
      - skipIfNotUpdated:
          switch:
            - condition: $${not resp.body.is_updated}
              return: true
      - assignStep:
          assign:
            - query0: |
                CREATE TEMP TABLE staging
                AS
                SELECT
            - query1: |
                FROM
                  landing;
                ASSERT 1 <= (SELECT COUNT(*) FROM staging) AS "empty table";
            - query: '$${ text.replace_all(query, "$${table}", "`" + body.loading.object + "`") }'
            - fields: []
      - loopStep:
          for:
            value: v
            range: $${[0, len(resp.body.names) - 1]}
            steps:
              - getStep:
                  assign:
                    - name: $${"f" + v}
                    - query0: $${query0 + "  " + name + " AS `" + text.replace_all_regex(resp.body.names[v], "[^\\p{L}\\p{N}\\p{Pc}\\p{Pd}\\p{M}&%=+:'<>#|]", "_") + "`,\n"}
                    - field:
                        name: $${name}
                        type: STRING
                    - fields: $${list.concat(fields, field)}
      - transformStep:
          call: googleapis.bigquery.v2.jobs.insert
          args:
            projectId: $${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
            body:
              configuration:
                query:
                  defaultDataset:
                    datasetId: US__${var.name}
                    projectId: $${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
                  query: '$${ query0 + query1 + query }'
                  tableDefinitions:
                    landing:
                      csvOptions:
                        allowQuotedNewlines: true
                        skipLeadingRows: 1
                      schema:
                        fields: $${fields}
                      sourceFormat: CSV
                      sourceUris:
                        - $${ "gs://" + body.loading.bucket + "/" + body.loading.object }
                  useLegacySql: false
  EOT
}
