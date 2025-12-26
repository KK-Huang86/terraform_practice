resource "aws_glue_catalog_database" "nginx_logs" {
  name = "nginx_logs_db"
}

# Glue Table
resource "aws_glue_catalog_table" "nginx_logs" {
  name          = "nginx_logs"
  database_name = aws_glue_catalog_database.nginx_logs.name

#讓 Athena 自動推斷 partition
  parameters = {
    "projection.enabled"    = "true"
    "projection.year.type"  = "integer"
    "projection.year.range" = "2024,2030"
    "projection.month.type" = "integer"
    "projection.month.range" = "1,12"
    "projection.month.digits" = "2"
    "projection.day.type"   = "integer"
    "projection.day.range"  = "1,31"
    "projection.day.digits" = "2"
    "projection.hour.type"  = "integer"
    "projection.hour.range" = "0,23"
    "projection.hour.digits" = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.nginx-logs.bucket}/nginx/$${year}/$${month}/$${day}/$${hour}/"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.nginx-logs.bucket}/nginx/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "method"
      type = "string"
    }
    columns {
      name = "uri"
      type = "string"
    }
    columns {
      name = "protocol"
      type = "string"
    }
    columns {
      name = "status"
      type = "int"
    }
    columns {
      name = "body_bytes_sent"
      type = "bigint"
    }
    columns {
      name = "http_referer"
      type = "string"
    }
    columns {
      name = "http_user_agent"
      type = "string"
    }
    columns {
      name = "request_time"
      type = "double"
    }
    columns {
      name = "hostname"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
  partition_keys {
    name = "hour"
    type = "string"
  }
}

# 創建 Athena 查詢結果的 S3 bucket
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.s3_bucket_name}-athena-results"  # 例如：nginx-logs-athena-results
}
# 設定 Athena Workgroup
resource "aws_athena_workgroup" "nginx_logs" {
  name = "nginx-logs-workgroup"
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/query-results/"
    }
  }
}