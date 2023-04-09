output "yaml" {
  value = <<-EOT
- http_to_cloud_storage_${random_uuid.default.result}:
    call: http.post
    args:
      url: ${var.simplte_url}
      auth:
        type: OIDC
      body:
        extraction:
          ${indent(10, yamlencode(var.extraction))}
        tweaks:
          %{ for k, v in var.tweaks ~}

          - call: ${v.call}
            args:
              ${yamlencode(coalesce(v.args, {}))}
          %{~ endfor }
        loading:
          bucket: ${google_storage_bucket.default.name}
          object: ${local.name}
EOT
}

output "bucket_name" {
  value = google_storage_bucket.default.name
}

output "object_name" {
  value = local.name
}
