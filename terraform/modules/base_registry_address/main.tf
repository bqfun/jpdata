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
      fields = [
        "local_government_code",
        "prefecture",
        "prefecture_kana",
        "prefecture_en",
        "effective_from",
        "effective_to",
        "remarks",
      ]
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
          local_government_code,
          prefecture,
          prefecture_kana,
          prefecture_en,
          PARSE_DATE("%Y-%m-%d", effective_from) AS effective_from,
          PARSE_DATE("%Y-%m-%d", effective_to) AS effective_to,
          remarks,
        FROM
          $${staging}
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
      fields = [
        "local_government_code",
        "prefecture",
        "prefecture_kana",
        "prefecture_en",
        "district",
        "district_kana",
        "district_en",
        "city",
        "city_kana",
        "city_en",
        "government_ordinance_city",
        "government_ordinance_city_kana",
        "government_ordinance_city_en",
        "effective_from",
        "effective_to",
        "remarks",
      ]
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
          local_government_code,
          prefecture,
          prefecture_kana,
          prefecture_en,
          district,
          district_kana,
          district_en,
          city,
          city_kana,
          city_en,
          government_ordinance_city,
          government_ordinance_city_kana,
          government_ordinance_city_en,
          PARSE_DATE("%Y-%m-%d", effective_from) AS effective_from,
          PARSE_DATE("%Y-%m-%d", effective_to) AS effective_to,
          remarks,
        FROM
          $${staging}
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
      fields = [
        "local_government_code",
        "town_id",
        "town_classification_code",
        "prefecture",
        "prefecture_kana",
        "prefecture_en",
        "district",
        "district_kana",
        "district_en",
        "city",
        "city_kana",
        "city_en",
        "government_ordinance_city",
        "government_ordinance_city_kana",
        "government_ordinance_city_en",
        "ooaza",
        "ooaza_kana",
        "ooaza_en",
        "chome",
        "chome_kana",
        "chome_number",
        "koaza",
        "koaza_kana",
        "koaza_en",
        "is_residential",
        "_01",
        "_02",
        "_03",
        "_04",
        "_05",
        "_06",
        "_07",
        "effective_from",
        "effective_to",
        "original_data_code",
        "postal_code",
        "remarks",
      ]
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          PRIMARY KEY (local_government_code, town_id, is_residential) NOT ENFORCED,
          local_government_code STRING NOT NULL OPTIONS(description="全国地方公共団体コード"),
          town_id STRING NOT NULL OPTIONS(description="町字id"),
          town_classification_code STRING NOT NULL OPTIONS(description="町字区分コード"),
          prefecture STRING NOT NULL OPTIONS(description="都道府県名"),
          prefecture_kana STRING NOT NULL OPTIONS(description="都道府県名_カナ"),
          prefecture_en STRING NOT NULL OPTIONS(description="都道府県名_英字"),
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
          _01 STRING OPTIONS(description="住居表示方式コード"),
          _02 STRING OPTIONS(description="大字・町_通称フラグ"),
          _03 STRING OPTIONS(description="小字_通称フラグ"),
          _04 STRING OPTIONS(description="大字・町外字フラグ"),
          _05 STRING OPTIONS(description="小字外字フラグ"),
          _06 STRING OPTIONS(description="状態フラグ"),
          _07 STRING OPTIONS(description="起番フラグ"),
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
          local_government_code,
          town_id,
          town_classification_code,
          prefecture,
          prefecture_kana,
          prefecture_en,
          district,
          district_kana,
          district_en,
          city,
          city_kana,
          city_en,
          government_ordinance_city,
          government_ordinance_city_kana,
          government_ordinance_city_en,
          ooaza,
          ooaza_kana,
          ooaza_en,
          chome,
          chome_kana,
          CAST(chome_number AS INT64) AS chome_number,
          koaza,
          koaza_kana,
          koaza_en,
          CASE is_residential
            WHEN "1" THEN TRUE
            WHEN "0" THEN FALSE
            ELSE ERROR("Unsupported is_residential: " || IFNULL(is_residential, "NULL"))
          END AS is_residential,
          _01,
          _02,
          _03,
          _04,
          _05,
          _06,
          _07,
          PARSE_DATE("%Y-%m-%d", effective_from) AS effective_from,
          PARSE_DATE("%Y-%m-%d", effective_to) AS effective_to,
          original_data_code,
          postal_code,
          remarks,
        FROM
          $${staging}
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
