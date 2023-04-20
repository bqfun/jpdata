locals {
  pref = {
    name = "pref"
    extraction = {
      url = "https://catalog.registries.digital.go.jp/rsc/address/mt_pref_all.csv.zip"
    }
    tweaks = [
      {
        call = "unzip"
      }
    ]
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          local_government_code STRING OPTIONS(description="全国地方公共団体コード"),
          prefecture STRING OPTIONS(description="都道府県名"),
          prefecture_kana STRING OPTIONS(description="都道府県名_カナ"),
          prefecture_en STRING OPTIONS(description="都道府県名_英字"),
          effective_from DATE OPTIONS(description="効力発生日"),
          effective_to DATE OPTIONS(description="廃止日"),
          remarks STRING OPTIONS(description="備考"),
        )
        OPTIONS(
          description="https://catalog.registries.digital.go.jp/rsc/address/mt_pref_all.csv.zip",
          friendly_name="日本 都道府県マスター データセット",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          `全国地方公共団体コード` AS local_government_code,
          `都道府県名` AS prefecture,
          `都道府県名_カナ` AS prefecture_kana,
          `都道府県名_英字` AS prefecture_en,
          PARSE_DATE("%Y-%m-%d", `効力発生日`) AS effective_from,
          PARSE_DATE("%Y-%m-%d", `廃止日`) AS effective_to,
          `備考` AS remarks,
        FROM
          staging
        EOF
    }
  }
  city = {
    name = "city"
    extraction = {
      url = "https://catalog.registries.digital.go.jp/rsc/address/mt_city_all.csv.zip"
    }
    tweaks = [
      {
        call = "unzip"
      }
    ]
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          local_government_code STRING OPTIONS(description="全国地方公共団体コード"),
          prefecture STRING OPTIONS(description="都道府県名"),
          prefecture_kana STRING OPTIONS(description="都道府県名_カナ"),
          prefecture_en STRING OPTIONS(description="都道府県名_英字"),
          district STRING OPTIONS(description="郡名"),
          district_kana STRING OPTIONS(description="郡名_カナ"),
          district_en STRING OPTIONS(description="郡名_英字"),
          city STRING OPTIONS(description="市区町村名"),
          city_kana STRING OPTIONS(description="市区町村名_カナ"),
          city_en STRING OPTIONS(description="市区町村名_英字"),
          government_ordinance_city STRING OPTIONS(description="政令市区名"),
          government_ordinance_city_kana STRING OPTIONS(description="政令市区名_カナ"),
          government_ordinance_city_en STRING OPTIONS(description="政令市区名_英字"),
          effective_from DATE OPTIONS(description="効力発生日"),
          effective_to DATE OPTIONS(description="廃止日"),
          remarks STRING OPTIONS(description="備考"),
        )
        OPTIONS(
          description="https://catalog.registries.digital.go.jp/rsc/address/mt_city_all.csv.zip",
          friendly_name="日本 市区町村マスター データセット",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          `全国地方公共団体コード` AS local_government_code,
          `都道府県名` AS prefecture,
          `都道府県名_カナ` AS prefecture_kana,
          `都道府県名_英字` AS prefecture_en,
          `郡名` AS district,
          `郡名_カナ` AS district_kana,
          `郡名_英字` AS district_en,
          `市区町村名` AS city,
          `市区町村名_カナ` AS city_kana,
          `市区町村名_英字` AS city_en,
          `政令市区名` AS government_ordinance_city,
          `政令市区名_カナ` AS government_ordinance_city_kana,
          `政令市区名_英字` AS government_ordinance_city_en,
          PARSE_DATE("%Y-%m-%d", `効力発生日`) AS effective_from,
          PARSE_DATE("%Y-%m-%d", `廃止日`) AS effective_to,
          `備考` AS remarks,
        FROM
          staging
        EOF
    }
  }
  town = {
    name = "town"
    extraction = {
      url = "https://catalog.registries.digital.go.jp/rsc/address/mt_town_all.csv.zip"
    }
    tweaks = [
      {
        call = "unzip"
      }
    ]
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          PRIMARY KEY (local_government_code, town_id, is_residential) NOT ENFORCED,
          local_government_code STRING NOT NULL OPTIONS(description="全国地方公共団体コード"),
          town_id STRING NOT NULL OPTIONS(description="町字id"),
          town_classification_code STRING NOT NULL OPTIONS(description="町字区分コード"),
          prefecture STRING NOT NULL OPTIONS(description="都道府県名"),
          prefecture_kana STRING NOT NULL OPTIONS(description="都道府県名_カナ"),
          prefecture_en STRING OPTIONS(description="都道府県名_英字"),
          district STRING OPTIONS(description="郡名"),
          district_kana STRING OPTIONS(description="郡名_カナ"),
          district_en STRING OPTIONS(description="郡名_英字"),
          city STRING NOT NULL OPTIONS(description="市区町村名"),
          city_kana STRING NOT NULL OPTIONS(description="市区町村名_カナ"),
          city_en STRING NOT NULL OPTIONS(description="市区町村名_英字"),
          government_ordinance_city STRING OPTIONS(description="政令市区名"),
          government_ordinance_city_kana STRING OPTIONS(description="政令市区名_カナ"),
          government_ordinance_city_en STRING OPTIONS(description="政令市区名_英字"),
          ooaza STRING OPTIONS(description="大字・町名"),
          ooaza_kana STRING OPTIONS(description="大字・町名_カナ"),
          ooaza_en STRING OPTIONS(description="大字・町名_英字"),
          chome STRING OPTIONS(description="丁目名"),
          chome_kana STRING OPTIONS(description="丁目名_カナ"),
          chome_number INTEGER OPTIONS(description="丁目名_数字"),
          koaza STRING OPTIONS(description="小字名"),
          koaza_kana STRING OPTIONS(description="小字名_カナ"),
          koaza_en STRING OPTIONS(description="小字名_英字"),
          is_residential BOOL OPTIONS(description="住居表示フラグ"),
          residential_address_method STRING OPTIONS(description="住居表示方式コード"),
          has_ooaza_alias BOOL OPTIONS(description="大字・町名_通称フラグ"),
          has_koaza_alias BOOL OPTIONS(description="小字名_通称フラグ"),
          ooaza_non_standard_characters STRING OPTIONS(description="大字・町名_電子国土基本図外字"),
          koaza_non_standard_characters STRING OPTIONS(description="小字名_電子国土基本図外字"),
          verification_status STRING OPTIONS(description="状態フラグ"),
          numbering_status STRING OPTIONS(description="起番フラグ"),
          effective_from DATE NOT NULL OPTIONS(description="効力発生日"),
          effective_to DATE OPTIONS(description="廃止日"),
          original_data_code STRING NOT NULL OPTIONS(description="原典資料コード"),
          postal_code STRING OPTIONS(description="郵便番号"),
          remarks STRING OPTIONS(description="備考"),
        )
        OPTIONS(
          description="https://catalog.registries.digital.go.jp/rsc/address/mt_town_all.csv.zip",
          friendly_name="日本 町字マスター データセット",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          `全国地方公共団体コード` AS local_government_code,
          `町字id` AS town_id,
          `町字区分コード` AS town_classification_code,
          `都道府県名` AS prefecture,
          `都道府県名_カナ` AS prefecture_kana,
          `政令市区名_英字` AS prefecture_en,
          `郡名` AS district,
          `郡名_カナ` AS district_kana,
          `郡名_英字` AS district_en,
          `市区町村名` AS city,
          `市区町村名_カナ` AS city_kana,
          `市区町村名_英字` AS city_en,
          `政令市区名` AS government_ordinance_city,
          `政令市区名_カナ` AS government_ordinance_city_kana,
          `政令市区名_英字` AS government_ordinance_city_en,
          `大字_町名` AS ooaza,
          `大字_町名_カナ` AS ooaza_kana,
          `大字_町名_英字` AS ooaza_en,
          `丁目名` AS chome,
          `丁目名_カナ` AS chome_kana,
          CAST(`丁目名_数字` AS INT64) AS chome_number,
          `小字名` AS koaza,
          `小字名_カナ` AS koaza_kana,
          `小字名_英字` AS koaza_en,
          CASE `住居表示フラグ`
            WHEN "1" THEN TRUE
            WHEN "0" THEN FALSE
            ELSE ERROR("Unsupported is_residential: " || IFNULL(`住居表示フラグ`, "NULL"))
          END AS is_residential,
          CASE `住居表示方式コード`
            WHEN "1" THEN "街区方式"
            WHEN "2" THEN "道路方式"
            WHEN "0" THEN "住居表示でない"
            ELSE ERROR("Unsupported residential_address_method: " || IFNULL(`住居表示方式コード`, "NULL"))
          END AS residential_address_method,
          CASE `大字_町名_通称フラグ`
            WHEN "0" THEN FALSE
            WHEN "1" THEN TRUE
            ELSE ERROR("Unsupported has_ooaza_alias: " || IFNULL(`大字_町名_通称フラグ`, "NULL"))
          END AS has_ooaza_alias,
          CASE `小字名_通称フラグ`
            WHEN "0" THEN FALSE
            WHEN "1" THEN TRUE
            ELSE ERROR("Unsupported has_koaza_alias: " || IFNULL(`小字名_通称フラグ`, "NULL"))
          END AS has_koaza_alias,
          NULLIF(`大字_町名_電子国土基本図外字`, "0") AS ooaza_non_standard_characters,
          NULLIF(`小字名_電子国土基本図外字`, "0") AS koaza_non_standard_characters,
          CASE `状態フラグ`
            WHEN "0" THEN "自治体確認待ち"
            WHEN "1" THEN "地方自治法の町若しくは字に該当"
            WHEN "2" THEN "地方自治法の町若しくは字に非該当"
            WHEN "3" THEN "不明"
            ELSE ERROR("Unsupported verification_status: " || IFNULL(`状態フラグ`, "NULL"))
          END AS verification_status,
          CASE `起番フラグ`
            WHEN "1" THEN "起番"
            WHEN "2" THEN "非起番"
            WHEN "0" THEN "登記情報に存在しない"
            ELSE ERROR("Unsupported numbering_status: " || IFNULL(`起番フラグ`, "NULL"))
          END AS numbering_status,
          PARSE_DATE("%Y-%m-%d", `効力発生日`) AS effective_from,
          PARSE_DATE("%Y-%m-%d", `廃止日`) AS effective_to,
          `原典資料コード` AS original_data_code,
          `郵便番号` AS postal_code,
          `備考` AS remarks,
        FROM
          staging
        QUALIFY
          IF(1=COUNT(*)OVER(PARTITION BY local_government_code, town_id, is_residential), TRUE, ERROR("Duplicated keys found"))
        EOF
    }
  }
}

module "main" {
  source         = "../../modules/workflows_http_to_bigquery_datasets"
  name           = "base_registry_address"
  tweakle_cpu    = "0.08"
  tweakle_memory = "512Mi"
  etlt = [
    local.city,
    local.town,
    local.pref,
  ]
}
