locals {
  basic = {
    name = "basic"
    extraction = {
      url    = "https://info.gbiz.go.jp/hojin/Download"
      method = "POST"
      body = {
        downenc  = "UTF-8"
        downfile = "7"
        downtype = "csv"
      }
    }
    tweaks = []
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          corporate_number STRING OPTIONS(description="法人番号"),
          name STRING OPTIONS(description="法人名"),
          kana STRING OPTIONS(description="法人名ふりがな"),
          name_en STRING OPTIONS(description="法人名英語"),
          postal_code STRING OPTIONS(description="郵便番号"),
          location STRING OPTIONS(description="本社所在地"),
          status STRING OPTIONS(description="ステータス"),
          close_date DATE OPTIONS(description="登記記録の閉鎖等年月日"),
          close_cause STRING OPTIONS(description="登記記録の閉鎖等の事由"),
          representative_name STRING OPTIONS(description="法人代表者名"),
          representative_position STRING OPTIONS(description="法人代表者役職"),
          capital_stock INT64 OPTIONS(description="資本金"),
          employee_number INT64 OPTIONS(description="従業員数"),
          company_size_male INT64 OPTIONS(description="企業規模詳細(男性)"),
          company_size_female INT64 OPTIONS(description="企業規模詳細(女性)"),
          business_items ARRAY<
            STRUCT<
              business_item_code STRING OPTIONS(description="営業品目コード値"),
              business_item_name STRING OPTIONS(description="営業品目コード値(日本語)")
            >
          > OPTIONS(description="営業品目リスト"),
          business_summary STRING OPTIONS(description="事業概要"),
          company_url STRING OPTIONS(description="企業ホームページ"),
          date_of_establishment DATE OPTIONS(description="設立年月日"),
          founding_year INT64 OPTIONS(description="創業年"),
          update_date DATE OPTIONS(description="最終更新日"),
        )
        OPTIONS(
          description="https://info.gbiz.go.jp/hojin/Download",
          friendly_name="基本情報",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          IF(`法人番号` <> "", `法人番号`, ERROR('(`法人番号` <> "") IS NOT TRUE')) AS corporate_number,
          NULLIF(`法人名`, "") AS name,
          NULLIF(`法人名ふりがな`, "") AS kana,
          NULLIF(`法人名英語`, "") AS name_en,
          CASE
            WHEN `郵便番号` = "" THEN NULL
            WHEN REGEXP_CONTAINS(`郵便番号`, "^[0-9]{7}$") THEN `郵便番号`
            ELSE ERROR('`郵便番号` IS NULL OR NOT REGEXP_CONTAINS(`郵便番号`, "^[0-9]{7}$")')
          END AS postal_code,
          NULLIF(`本社所在地`, "") AS location,
          NULLIF(`ステータス`, "") AS status,
          PARSE_DATE("%Y-%m-%d", NULLIF(`登記記録の閉鎖等年月日`, "")) AS close_date,
          CASE `登記記録の閉鎖等の事由`
            WHEN "" THEN NULL
            WHEN "01" THEN "清算の結了等"
            WHEN "11" THEN "合併による解散等"
            WHEN "21" THEN "登記官による閉鎖"
            WHEN "31" THEN "その他の清算の結了等"
            ELSE ERROR('`` NOT IN ("", "01", "21", "31")')
          END AS close_cause,
          NULLIF(`法人代表者名`, "") AS representative_name,
          NULLIF(`法人代表者役職`, "") AS representative_position,
          CAST(NULLIF(`資本金`, "") AS INT64) AS capital_stock,
          CAST(NULLIF(`従業員数`, "") AS INT64) AS employee_number,
          CAST(NULLIF(`企業規模詳細_男性_`, "") AS INT64) AS company_size_male,
          CAST(NULLIF(`企業規模詳細_女性_`, "") AS INT64) AS company_size_female,
          ARRAY(
            SELECT AS STRUCT
              business_item_code,
              CASE business_item_code
                WHEN "101" THEN "衣服・その他繊維製品類"
                WHEN "102" THEN "ゴム・皮革・プラスチック製品類"
                WHEN "103" THEN "窯業・土石製品類"
                WHEN "104" THEN "非鉄金属・金属製品類"
                WHEN "105" THEN "フォーム印刷"
                WHEN "106" THEN "その他印刷類"
                WHEN "107" THEN "図書類"
                WHEN "108" THEN "電子出版物類"
                WHEN "109" THEN "紙・紙加工品類"
                WHEN "110" THEN "車両類"
                WHEN "111" THEN "その他輸送・搬送機械器具類"
                WHEN "112" THEN "船舶類"
                WHEN "113" THEN "燃料類"
                WHEN "114" THEN "家具・什器類"
                WHEN "115" THEN "一般・産業用機器類"
                WHEN "116" THEN "電気・通信用機器類"
                WHEN "117" THEN "電子計算機類"
                WHEN "118" THEN "精密機器類"
                WHEN "119" THEN "医療用機器類"
                WHEN "120" THEN "事務用機器類"
                WHEN "121" THEN "その他機器類"
                WHEN "122" THEN "医薬品・医療用品類"
                WHEN "123" THEN "事務用品類"
                WHEN "124" THEN "土木・建設・建築材料"
                WHEN "127" THEN "警察用装備品類"
                WHEN "128" THEN "防衛用装備品類"
                WHEN "129" THEN "その他"
                WHEN "201" THEN "衣服・その他繊維製品類"
                WHEN "202" THEN "ゴム・皮革・プラスチック製品類"
                WHEN "203" THEN "窯業・土石製品類"
                WHEN "204" THEN "非鉄金属・金属製品類"
                WHEN "205" THEN "フォーム印刷"
                WHEN "206" THEN "その他印刷類"
                WHEN "207" THEN "図書類"
                WHEN "208" THEN "電子出版物類"
                WHEN "209" THEN "紙・紙加工品類"
                WHEN "210" THEN "車両類"
                WHEN "211" THEN "その他輸送・搬送機械器具類"
                WHEN "212" THEN "船舶類"
                WHEN "213" THEN "燃料類"
                WHEN "214" THEN "家具・什器類"
                WHEN "215" THEN "一般・産業用機器類"
                WHEN "216" THEN "電気・通信用機器類"
                WHEN "217" THEN "電子計算機類"
                WHEN "218" THEN "精密機器類"
                WHEN "219" THEN "医療用機器類"
                WHEN "220" THEN "事務用機器類"
                WHEN "221" THEN "その他機器類"
                WHEN "222" THEN "医薬品・医療用品類"
                WHEN "223" THEN "事務用品類"
                WHEN "224" THEN "土木・建設・建築材料"
                WHEN "225" THEN "造幣・印刷事業用原材料類"
                WHEN "226" THEN "造幣事業用金属工芸品類"
                WHEN "227" THEN "警察用装備品類"
                WHEN "228" THEN "防衛用装備品類"
                WHEN "229" THEN "その他"
                WHEN "301" THEN "広告・宣伝"
                WHEN "302" THEN "写真・製図"
                WHEN "303" THEN "調査・研究"
                WHEN "304" THEN "情報処理"
                WHEN "305" THEN "翻訳・通訳・速記"
                WHEN "306" THEN "ソフトウェア開発"
                WHEN "307" THEN "会場等の借り上げ"
                WHEN "308" THEN "賃貸借"
                WHEN "309" THEN "建物管理等各種保守管理"
                WHEN "310" THEN "運送"
                WHEN "311" THEN "車両整備"
                WHEN "312" THEN "船舶整備"
                WHEN "313" THEN "電子出版"
                WHEN "314" THEN "防衛用装備品類の整備"
                WHEN "315" THEN "その他"
                WHEN "401" THEN "立木竹"
                WHEN "402" THEN "その他"
                ELSE ERROR("Unsupported business_item_code: " || business_item_code)
              END AS business_item_name
            FROM
              UNNEST(SPLIT(NULLIF(`営業品目リスト`, ""), "、")) AS business_item_code WITH OFFSET
            ORDER BY
              OFFSET
          ) AS business_items,
          NULLIF(`事業概要`, "") AS business_summary,
          NULLIF(`企業ホームページ`, "") AS company_url,
          PARSE_DATE("%Y-%m-%d", NULLIF(`設立年月日`, "")) AS date_of_establishment,
          CAST(NULLIF(`創業年`, "") AS INT64) AS founding_year,
          IF(`最終更新日` = "", NULL, IFNULL(SAFE.PARSE_DATE("%Y-%m-%dT00:00:00+09:00", `最終更新日`), PARSE_DATE("%Y-%m-%dT00:00:00Z", `最終更新日`))) AS update_date,
        FROM
          staging
        EOF
    }
  }
  certification = {
    name = "certification"
    extraction = {
      url    = "https://info.gbiz.go.jp/hojin/Download"
      method = "POST"
      body = {
        downenc  = "UTF-8"
        downfile = "8"
        downtype = "csv"
      }
    }
    tweaks = []
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          corporate_number STRING OPTIONS(description="法人番号"),
          name STRING OPTIONS(description="法人名"),
          location STRING OPTIONS(description="本社所在地"),
          date_of_approval DATE OPTIONS(description="認定日"),
          title STRING OPTIONS(description="届出認定等"),
          target STRING OPTIONS(description="対象"),
          category STRING OPTIONS(description="部門"),
          enterprise_scale STRING OPTIONS(description="企業規模"),
          expiration_date DATE OPTIONS(description="有効期限"),
          government_departments STRING OPTIONS(description="府省"),
        )
        OPTIONS(
          description="https://info.gbiz.go.jp/hojin/Download",
          friendly_name="届出認定情報",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          IF(`法人番号` <> "", `法人番号`, ERROR('(`法人番号` <> "") IS NOT TRUE')) AS corporate_number,
          IF(`法人名` <> "", `法人名`, ERROR('(`法人名` <> "") IS NOT TRUE')) AS name,
          NULLIF(`本社所在地`, "") AS location,
          PARSE_DATE("%Y-%m-%d", NULLIF(`認定日`, "")) AS date_of_approval,
          IF(`届出認定等` <> "", `届出認定等`, ERROR('(`届出認定等` <> "") IS NOT TRUE')) AS title,
          NULLIF(`対象`, "") AS target,
          NULLIF(`部門`, "") AS category,
          CASE `企業規模`
            WHEN "" THEN NULL
            WHEN "1" THEN "大企業"
            WHEN "2" THEN "中企業"
            WHEN "3" THEN "その他"
            WHEN "4" THEN "未定義"
          END AS enterprise_scale,
          PARSE_DATE("%Y-%m-%d", NULLIF(`有効期限`, "")) AS expiration_date,
          IF(`府省` <> "", `府省`, ERROR('(`府省` <> "") IS NOT TRUE')) AS government_departments,
        FROM
          staging
        EOF
    }
  }
  commendation = {
    name = "commendation"
    extraction = {
      url    = "https://info.gbiz.go.jp/hojin/Download"
      method = "POST"
      body = {
        downenc  = "UTF-8"
        downfile = "9"
        downtype = "csv"
      }
    }
    tweaks = []
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          corporate_number STRING OPTIONS(description="法人番号"),
          name STRING OPTIONS(description="法人名"),
          location STRING OPTIONS(description="本社所在地"),
          date_of_commendation DATE OPTIONS(description="年月日"),
          title STRING OPTIONS(description="表彰名"),
          target STRING OPTIONS(description="受賞対象"),
          category STRING OPTIONS(description="部門"),
          government_departments STRING OPTIONS(description="府省"),
        )
        OPTIONS(
          description="https://info.gbiz.go.jp/hojin/Download",
          friendly_name="表彰情報",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          IF(`法人番号` <> "", `法人番号`, ERROR('(`法人番号` <> "") IS NOT TRUE')) AS corporate_number,
          IF(`法人名` <> "", `法人名`, ERROR('(`法人名` <> "") IS NOT TRUE')) AS name,
          NULLIF(`本社所在地`, "") AS location,
          PARSE_DATE("%Y-%m-%d", NULLIF(`年月日`, "")) AS date_of_commendation,
          NULLIF(`表彰名`, "") AS title,
          NULLIF(`受賞対象`, "") AS target,
          NULLIF(`部門`, "") AS category,
          IF(`府省` <> "", `府省`, ERROR('(`府省` <> "") IS NOT TRUE')) AS government_departments,
        FROM
          staging
        EOF
    }
  }
  subsidy = {
    name = "subsidy"
    extraction = {
      url    = "https://info.gbiz.go.jp/hojin/Download"
      method = "POST"
      body = {
        downenc  = "UTF-8"
        downfile = "10"
        downtype = "csv"
      }
    }
    tweaks = []
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          corporate_number STRING OPTIONS(description="法人番号"),
          name STRING OPTIONS(description="法人名"),
          location STRING OPTIONS(description="本社所在地"),
          date_of_approval DATE OPTIONS(description="認定日"),
          title STRING OPTIONS(description="補助金等"),
          amount INT64 OPTIONS(description="金額"),
          target STRING OPTIONS(description="対象"),
          government_departments STRING OPTIONS(description="府省"),
          note STRING OPTIONS(description="備考"),
          joint_signatures ARRAY<STRING> OPTIONS(description="連名リスト"),
          subsidy_resource STRING OPTIONS(description="補助金財源"),
        )
        OPTIONS(
          description="https://info.gbiz.go.jp/hojin/Download",
          friendly_name="補助金情報",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          IF(`法人番号` <> "", `法人番号`, ERROR('(`法人番号` <> "") IS NOT TRUE')) AS corporate_number,
          IF(`法人名` <> "", `法人名`, ERROR('(`法人名` <> "") IS NOT TRUE')) AS name,
          NULLIF(`本社所在地`, "") AS location,
          PARSE_DATE("%Y-%m-%d", NULLIF(`認定日`, "")) AS date_of_approval,
          NULLIF(`補助金等`, "") AS title,
          CAST(NULLIF(`金額`, "") AS INT64) AS amount,
          NULLIF(`対象`, "") AS target,
          IF(`府省` <> "", `府省`, ERROR('(`府省` <> "") IS NOT TRUE')) AS government_departments,
          NULLIF(`備考`, "") AS note,
          SPLIT(NULLIF(`連名リスト`, ""), "、") AS joint_signatures,
          NULLIF(`補助金財源`, "") AS subsidy_resource,
        FROM
          staging
        EOF
    }
  }
  procurement = {
    name = "procurement"
    extraction = {
      url    = "https://info.gbiz.go.jp/hojin/Download"
      method = "POST"
      body = {
        downenc  = "UTF-8"
        downfile = "11"
        downtype = "csv"
      }
    }
    tweaks = []
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          corporate_number STRING OPTIONS(description="法人番号"),
          name STRING OPTIONS(description="法人名"),
          location STRING OPTIONS(description="本社所在地"),
          date_of_order DATE OPTIONS(description="受注日"),
          title STRING OPTIONS(description="事業名"),
          amount INT64 OPTIONS(description="金額"),
          government_departments STRING OPTIONS(description="府省"),
          joint_signatures ARRAY<STRING> OPTIONS(description="連名リスト"),
        )
        OPTIONS(
          description="https://info.gbiz.go.jp/hojin/Download",
          friendly_name="調達情報",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          IF(`法人番号` <> "", `法人番号`, ERROR('(`法人番号` <> "") IS NOT TRUE')) AS corporate_number,
          IF(`法人名` <> "", `法人名`, ERROR('(`法人名` <> "") IS NOT TRUE')) AS name,
          NULLIF(`本社所在地`, "") AS location,
          PARSE_DATE("%Y-%m-%dT00:00:00+09:00", NULLIF(`受注日`, "")) AS date_of_order,
          NULLIF(`事業名`, "") AS title,
          CAST(NULLIF(`金額`, "") AS INT64) AS amount,
          IF(`府省` <> "", `府省`, ERROR('(`府省` <> "") IS NOT TRUE')) AS government_departments,
          SPLIT(NULLIF(`連名リスト`, ""), "、") AS joint_signatures,
        FROM
          staging
        EOF
    }
  }
  patent = {
    name = "patent"
    extraction = {
      url    = "https://info.gbiz.go.jp/hojin/Download"
      method = "POST"
      body = {
        downenc  = "UTF-8"
        downfile = "12"
        downtype = "csv"
      }
    }
    tweaks = []
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          corporate_number STRING OPTIONS(description="法人番号"),
          name STRING OPTIONS(description="法人名"),
          location STRING OPTIONS(description="本社所在地"),
          patent_type STRING OPTIONS(description="特許/意匠/商標"),
          application_number STRING OPTIONS(description="出願番号"),
          application_date DATE OPTIONS(description="出願年月日"),
          patent_classification_fi_code STRING OPTIONS(description="特許_FI分類_コード値"),
          patent_classification_fi_name STRING OPTIONS(description="特許_FI分類_コード値(日本語)"),
          patent_classification_f_term_theme_code STRING OPTIONS(description="特許_Fターム-テーマコード"),
          design_classification_code STRING OPTIONS(description="意匠_意匠新分類_コード値"),
          design_classification_name STRING OPTIONS(description="意匠_意匠新分類_コード値(日本語)"),
          trademark_classification_code STRING OPTIONS(description="商標_類_コード値"),
          trademark_classification_name STRING OPTIONS(description="商標_類_コード値(日本語)"),
          title STRING OPTIONS(description="発明の名称(等)/意匠に係る物品/表示用商標"),
        )
        OPTIONS(
          description="https://info.gbiz.go.jp/hojin/Download",
          friendly_name="特許情報",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          IF(`法人番号` <> "", `法人番号`, ERROR('(`法人番号` <> "") IS NOT TRUE')) AS corporate_number,
          IF(`法人名` <> "", `法人名`, ERROR('(`法人名` <> "") IS NOT TRUE')) AS name,
          IF(`本社所在地` <> "", `本社所在地`, ERROR('(`本社所在地` <> "") IS NOT TRUE')) AS location,
          IF(`特許_意匠_商標` <> "", `特許_意匠_商標`, ERROR('(`特許_意匠_商標` <> "") IS NOT TRUE')) AS patent_type,
          IF(`出願番号` <> "", `出願番号`, ERROR('(`出願番号` <> "") IS NOT TRUE')) AS application_number,
          PARSE_DATE("%Y-%m-%d", `出願年月日`) AS application_date,
          NULLIF(`特許_FI分類_コード値`, "") AS patent_classification_fi_code,
          NULLIF(`特許_FI分類_コード値_日本語_`, "") AS patent_classification_fi_name,
          NULLIF(`特許_Fターム-テーマコード`, "") AS patent_classification_f_term_theme_code,
          NULLIF(`意匠_意匠新分類_コード値`, "") AS design_classification_code,
          NULLIF(`意匠_意匠新分類_コード値_日本語_`, "") AS design_classification_name,
          NULLIF(`商標_類_コード値`, "") AS trademark_classification_code,
          NULLIF(`商標_類_コード値_日本語_`, "") AS trademark_classification_name,
          IF(`発明の名称_等__意匠に係る物品_表示用商標` <> "", `発明の名称_等__意匠に係る物品_表示用商標`, ERROR('(`発明の名称_等__意匠に係る物品_表示用商標` <> "") IS NOT TRUE')) AS title,
        FROM
          staging
        EOF
    }
  }
  finance = {
    name = "finance"
    extraction = {
      url    = "https://info.gbiz.go.jp/hojin/Download"
      method = "POST"
      body = {
        downenc  = "UTF-8"
        downfile = "13"
        downtype = "csv"
      }
    }
    tweaks = []
    transformation = {
      query = <<-EOF
        CREATE TEMP FUNCTION TO_YEAR(year STRING) AS (
          IF(year = "元", 1, CAST(year AS INT64))
        );
        CREATE TEMP FUNCTION TO_DATE(s STRING) AS (
          IF(
            s IS NULL,
            NULL,
            DATE(
              CASE REGEXP_EXTRACT(s, r"^(令和|平成|)(?:元|\d+)年\d{1,2}月\d{1,2}日$")
                WHEN "令和" THEN 2018
                WHEN "平成" THEN 1988
                WHEN "" THEN 0
                ELSE ERROR(s)
              END
              + TO_YEAR(REGEXP_EXTRACT(s, r"^(?:令和|平成|)(元|\d+)年\d{1,2}月\d{1,2}日$")),
              CAST(REGEXP_EXTRACT(s, r"^(?:令和|平成|)(?:元|\d+)年(\d{1,2})月\d{1,2}日$") AS INT64),
              CAST(REGEXP_EXTRACT(s, r"^(?:令和|平成|)(?:元|\d+)年\d{1,2}月(\d{1,2})日$") AS INT64)
            )
          )
        );

        CREATE OR REPLACE TABLE $${table}(corporate_number STRING OPTIONS(description="法人番号"),
          name STRING OPTIONS(description="法人名"),
          location STRING OPTIONS(description="本社所在地"),
          accounting_standards STRING OPTIONS(description="会計基準"),
          fiscal_year_cover_page STRUCT<
            start_date DATE OPTIONS(description="期初日"),
            end_date DATE OPTIONS(description="期末日")
          > OPTIONS(description="事業年度"),
          period INT64 OPTIONS(description="回次"),
          net_sales_summary_of_business_results INT64 OPTIONS(description="売上高（円）"),
          operating_revenue1_summary_of_business_results INT64 OPTIONS(description="営業収益（円）"),
          operating_revenue2_summary_of_business_results INT64 OPTIONS(description="営業収入（円）"),
          gross_operating_revenue_summary_of_business_results INT64 OPTIONS(description="営業総収入（円）"),
          ordinary_income_summary_of_business_results INT64 OPTIONS(description="経常収益（円）"),
          net_premiums_written_summary_of_business_results_ins INT64 OPTIONS(description="正味収入保険料（円）"),
          ordinary_income_loss_summary_of_business_results INT64 OPTIONS(description="経常利益又は経常損失（△）（円）"),
          net_income_loss_summary_of_business_results INT64 OPTIONS(description="当期純利益又は当期純損失（△）（円）"),
          capital_stock_summary_of_business_results INT64 OPTIONS(description="資本金（円）"),
          net_assets_summary_of_business_results INT64 OPTIONS(description="純資産額（円）"),
          total_assets_summary_of_business_results INT64 OPTIONS(description="総資産額（円）"),
          number_of_employees INT64 OPTIONS(description="従業員数（人）"),
          major_shareholders ARRAY<
            STRUCT<
              name_major_shareholders STRING OPTIONS(description="氏名又は名称"),
              shareholding_ratio NUMERIC OPTIONS(description="発行済株式総数に対する所有株式数の割合")
            >
          > OPTIONS(description="大株主"),
        )
        OPTIONS(
          description="https://info.gbiz.go.jp/hojin/Download",
          friendly_name="財務情報",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          IF(`法人番号` <> "", `法人番号`, ERROR('(`法人番号` <> "") IS NOT TRUE')) AS corporate_number,
          IF(`法人名` <> "", `法人名`, ERROR('(`法人名` <> "") IS NOT TRUE')) AS name,
          IF(`本社所在地` <> "", `本社所在地`, ERROR('(`本社所在地` <> "") IS NOT TRUE')) AS location,
          NULLIF(`会計基準`, "") AS accounting_standards,
          CASE
            WHEN REGEXP_CONTAINS(`事業年度`, r"^自.+至.+$") THEN STRUCT(
              TO_DATE(REGEXP_EXTRACT(`事業年度`, r"^自(.+)至.+$")) AS start_date,
              TO_DATE(REGEXP_EXTRACT(`事業年度`, r"^自.+至(.+)$")) AS end_date
            )
            WHEN REGEXP_CONTAINS(`事業年度`, r"^.+から.+まで$") THEN STRUCT(
              TO_DATE(REGEXP_EXTRACT(`事業年度`, r"^(.+)から.+まで$")) AS start_date,
              TO_DATE(REGEXP_EXTRACT(`事業年度`, r"^.+から(.+)まで$")) AS end_date
            )
            ELSE ERROR("Unsupported `事業年度`: " || IFNULL(`事業年度`, "null"))
          END AS fiscal_year_cover_page,
          CASE `回次`
            WHEN "0" THEN 0
            WHEN "1" THEN 1
            WHEN "2" THEN 2
            WHEN "3" THEN 3
            WHEN "4" THEN 4
            ELSE ERROR("Unsupported `回次`: " || `回次`)
          END AS period,
          CASE
            WHEN `売上高` = "" THEN NULL
            WHEN `売上高_単位_` = "JPY" THEN CAST(`売上高` AS INT64)
            ELSE ERROR("`売上高`")
          END AS net_sales_summary_of_business_results,
          CASE
            WHEN `営業収益` = "" THEN NULL
            WHEN `営業収益_単位_` = "JPY" THEN CAST(`営業収益` AS INT64)
            ELSE ERROR("`営業収益`")
          END AS operating_revenue1_summary_of_business_results,
          CASE
            WHEN `営業収入` = "" THEN NULL
            WHEN `営業収入_単位_` = "JPY" THEN CAST(`営業収入` AS INT64)
            ELSE ERROR("`営業収入`")
          END AS operating_revenue2_summary_of_business_results,
          CASE
            WHEN `営業総収入` = "" THEN NULL
            WHEN `営業総収入_単位_` = "JPY" THEN CAST(`営業総収入` AS INT64)
            ELSE ERROR("`営業総収入`")
          END AS gross_operating_revenue_summary_of_business_results,
          CASE
            WHEN `経常収益` = "" THEN NULL
            WHEN `経常収益_単位_` = "JPY" THEN CAST(`経常収益` AS INT64)
            ELSE ERROR("`経常収益`")
          END AS ordinary_income_summary_of_business_results,
          CASE
            WHEN `正味収入保険料` = "" THEN NULL
            WHEN `正味収入保険料_単位_` = "JPY" THEN CAST(`正味収入保険料` AS INT64)
            ELSE ERROR("`正味収入保険料`")
          END AS net_premiums_written_summary_of_business_results_ins,
          CASE
            WHEN `経常利益又は経常損失___` = "" THEN NULL
            WHEN `経常利益又は経常損失____単位_` = "JPY" THEN CAST(`経常利益又は経常損失___` AS INT64)
            ELSE ERROR("`経常利益又は経常損失___`")
          END AS ordinary_income_loss_summary_of_business_results,
          CASE
            WHEN `当期純利益又は当期純損失___` = "" THEN NULL
            WHEN `当期純利益又は当期純損失____単位_` = "JPY" THEN CAST(`当期純利益又は当期純損失___` AS INT64)
            ELSE ERROR("`当期純利益又は当期純損失___`")
          END AS net_income_loss_summary_of_business_results,
          CASE
            WHEN `資本金` = "" THEN NULL
            WHEN `資本金_単位_` = "JPY" THEN CAST(`資本金` AS INT64)
            ELSE ERROR("`資本金`")
          END AS capital_stock_summary_of_business_results,
          CASE
            WHEN `純資産額` = "" THEN NULL
            WHEN `純資産額_単位_` = "JPY" THEN CAST(`純資産額` AS INT64)
            ELSE ERROR("`純資産額`")
          END AS net_assets_summary_of_business_results,
          CASE
            WHEN `総資産額` = "" THEN NULL
            WHEN `総資産額_単位_` = "JPY" THEN CAST(`総資産額` AS INT64)
            ELSE ERROR("`総資産額`")
          END AS total_assets_summary_of_business_results,
          CASE
            WHEN `従業員数` = "" THEN NULL
            WHEN `従業員数_単位_` = "pure" THEN CAST(`従業員数` AS INT64)
            ELSE ERROR("`従業員数`")
          END AS number_of_employees,
          ARRAY(
            SELECT AS STRUCT
              name_major_shareholders,
              CAST(NULLIF(shareholding_ratio, "") AS NUMERIC) AS shareholding_ratio,
            FROM
              UNNEST(ARRAY<STRUCT<id INT64, name_major_shareholders STRING, shareholding_ratio STRING>>[
                (1, `大株主1`, `発行済株式総数に対する所有株式数の割合1`),
                (2, `大株主2`, `発行済株式総数に対する所有株式数の割合2`),
                (3, `大株主3`, `発行済株式総数に対する所有株式数の割合3`),
                (4, `大株主4`, `発行済株式総数に対する所有株式数の割合4`),
                (5, `大株主5`, `発行済株式総数に対する所有株式数の割合5`)
              ])
            WHERE
              name_major_shareholders <> "" OR shareholding_ratio <> ""
            ORDER BY
              id
          ) AS major_shareholders,
        FROM (
          SELECT
            *REPLACE(
              REGEXP_EXTRACT(
                REGEXP_REPLACE(NORMALIZE(`事業年度`, NFKC), r"\p{Space}", ""),
                r"^(?:\d{4}年\d{1,2}月期\(第\d+期\)|\d{4}年\d{1,2}月期|\d{4}年度?|第\d+期\(\d{4}年\d{1,2}月期\)|第\d+期|\(第\d+期\))\((.+)\)$"
              ) AS `事業年度`
            )
          FROM
            staging
        )
        EOF
    }
  }
  workplace = {
    name = "workplace"
    extraction = {
      url    = "https://info.gbiz.go.jp/hojin/Download"
      method = "POST"
      body = {
        downenc  = "UTF-8"
        downfile = "14"
        downtype = "csv"
      }
    }
    tweaks = []
    transformation = {
      query = <<-EOF
        CREATE OR REPLACE TABLE $${table}(
          corporate_number STRING OPTIONS(description="法人番号"),
          name STRING OPTIONS(description="法人名"),
          location STRING OPTIONS(description="本社所在地"),
          average_continuous_service_years_type STRING OPTIONS(description="平均継続勤務年数-範囲"),
          average_continuous_service_years_male NUMERIC OPTIONS(description="平均継続勤務年数-男性"),
          average_continuous_service_years_female NUMERIC OPTIONS(description="平均継続勤務年数-女性"),
          average_continuous_service_years NUMERIC OPTIONS(description="正社員の平均継続勤務年数"),
          average_age NUMERIC OPTIONS(description="従業員の平均年齢"),
          month_average_predetermined_overtime_hours NUMERIC OPTIONS(description="月平均所定外労働時間"),
          female_workers_proportion_type STRING OPTIONS(description="労働者に占める女性労働者の割合-範囲"),
          female_workers_proportion NUMERIC OPTIONS(description="労働者に占める女性労働者の割合"),
          female_share_of_manager INT64 OPTIONS(description="女性管理職人数"),
          gender_total_of_manager INT64 OPTIONS(description="管理職全体人数（男女計）"),
          female_share_of_officers INT64 OPTIONS(description="女性役員人数"),
          gender_total_of_officers INT64 OPTIONS(description="役員全体人数（男女計）"),
          number_of_paternity_leave INT64 OPTIONS(description="育児休業対象者数（男性）"),
          number_of_maternity_leave INT64 OPTIONS(description="育児休業対象者数（女性）"),
          paternity_leave_acquisition_num INT64 OPTIONS(description="育児休業取得者数（男性）"),
          maternity_leave_acquisition_num INT64 OPTIONS(description="育児休業取得者数（女性）"),
        )
        OPTIONS(
          description="https://info.gbiz.go.jp/hojin/Download",
          friendly_name="職場情報",
          labels=[
            ("freshness", "daily")
          ]
        )
        AS
        SELECT
          IF(`法人番号` <> "", `法人番号`, ERROR('(`法人番号` <> "") IS NOT TRUE')) AS corporate_number,
          IF(`法人名` <> "",  `法人名`, ERROR('(`法人名` <> "") IS NOT TRUE')) AS name,
          NULLIF(`本社所在地`, "") AS location,
          NULLIF(`平均継続勤務年数-範囲`, "") AS average_continuous_service_years_type,
          CAST(NULLIF(`平均継続勤務年数-男性`, "") AS NUMERIC) AS average_continuous_service_years_male,
          CAST(NULLIF(`平均継続勤務年数-女性`, "") AS NUMERIC) AS average_continuous_service_years_female,
          CAST(NULLIF(`正社員の平均継続勤務年数`, "") AS NUMERIC) AS average_continuous_service_years,
          CAST(NULLIF(`従業員の平均年齢`, "") AS NUMERIC) AS average_age,
          CAST(NULLIF(`月平均所定外労働時間`, "") AS NUMERIC) AS month_average_predetermined_overtime_hours,
          NULLIF(`労働者に占める女性労働者の割合-範囲`, "") AS female_workers_proportion_type,
          CAST(NULLIF(`労働者に占める女性労働者の割合`, "") AS NUMERIC) AS female_workers_proportion,
          CAST(NULLIF(`女性管理職人数`, "") AS INT64) AS female_share_of_manager,
          CAST(NULLIF(`管理職全体人数_男女計_`, "") AS INT64) AS gender_total_of_manager,
          CAST(NULLIF(`女性役員人数`, "") AS INT64) AS female_share_of_officers,
          CAST(NULLIF(`役員全体人数_男女計_`, "") AS INT64) AS gender_total_of_officers,
          CAST(NULLIF(`育児休業対象者数_男性_`, "") AS INT64) AS number_of_paternity_leave,
          CAST(NULLIF(`育児休業対象者数_女性_`, "") AS INT64) AS number_of_maternity_leave,
          CAST(NULLIF(`育児休業取得者数_男性_`, "") AS INT64) AS paternity_leave_acquisition_num,
          CAST(NULLIF(`育児休業取得者数_女性_`, "") AS INT64) AS maternity_leave_acquisition_num,
        FROM
          staging
        EOF
    }
  }
}
module "main" {
  source         = "../../modules/workflows_http_to_bigquery_datasets"
  name           = "gbizinfo"
  tweakle_cpu    = "2"
  tweakle_memory = "8Gi"
  etlt = [
    local.basic,
    local.certification,
    local.commendation,
    local.subsidy,
    local.procurement,
    local.patent,
    local.finance,
    local.workplace,
  ]
}
