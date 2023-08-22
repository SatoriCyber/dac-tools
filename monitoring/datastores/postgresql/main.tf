terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}

module "monitor_postgresql_datastore_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"
  
  function_name = "monitor-postgresql-datastore-lambda"
  description   = "Lambda function that monitors postgresql datastore"
  handler       = "monitor-postgresql-datastore.main"
  runtime       = "python3.10"

  publish                  = true
  # architectures = ["arm64"] # enable if compiling on an arm64 computer

  source_path = "${path.module}/src"
  build_in_docker  = true
  
  timeout = 5

  environment_variables = {
    POSTGRESQL_DBNAME = var.postgresql_dbname,
    POSTGRESQL_USER = var.postgresql_user,
    POSTGRESQL_PASSWORD = var.postgresql_password,
    POSTGRESQL_SATORI_HOST = var.postgresql_satori_host,
    POSTGRESQL_QUERY = var.postgresql_query,
    POSTGRESQL_SATORI_PORT = var.postgresql_satori_port
  }
}

resource "aws_cloudwatch_event_rule" "schedule_monitor_postgresql_datastore_lambda" {
    name = "schedule-postgresql-datastore-lambda"
    description = "Schedule for monitor_postgresql_datastore lambda function"
    schedule_expression = "rate(${var.cron_interval} minutes)"
}

resource "aws_cloudwatch_event_target" "schedule_monitor_postgresql_datastore_lambda" {
    rule = resource.aws_cloudwatch_event_rule.schedule_monitor_postgresql_datastore_lambda.name
    target_id = "processing_monitor_postgresql_datastore_lambda"
    arn = module.monitor_postgresql_datastore_lambda_function.lambda_function_arn
}


resource "aws_lambda_permission" "allow_events_bridge_to_run_monitor_postgresql_datastore_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = module.monitor_postgresql_datastore_lambda_function.lambda_function_name
    principal = "events.amazonaws.com"
}