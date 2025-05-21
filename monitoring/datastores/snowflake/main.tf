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

module "monitor_snowflake_datastore_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "monitor-snowflake-datastore-lambda"
  description   = "Lambda function that monitors snowflake datastore"
  handler       = "monitor-snowflake-datastore.main"
  runtime       = "python3.10"

  publish = true

  source_path     = "${path.module}/src"
  build_in_docker = true

  timeout = 5

  environment_variables = {
    SNOWFLAKE_USER        = var.snowflake_user,
    SNOWFLAKE_PASSWORD    = var.snowflake_password,
    SNOWFLAKE_ACCOUNT     = var.snowflake_account,
    SNOWFLAKE_SATORI_HOST = var.snowflake_satori_host,
    SNOWFLAKE_WAREHOUSE   = var.snowflake_warehouse
  }
}

resource "aws_cloudwatch_event_rule" "schedule_monitor_snowflake_datastore_lambda" {
  name                = "schedule-snowflake-datastore-lambda"
  description         = "Schedule for monitor_snowflake_datastore lambda function"
  schedule_expression = "rate(${var.cron_interval} minutes)"
}

resource "aws_cloudwatch_event_target" "schedule_monitor_snowflake_datastore_lambda" {
  rule      = resource.aws_cloudwatch_event_rule.schedule_monitor_snowflake_datastore_lambda.name
  target_id = "processing_monitor_snowflake_datastore_lambda"
  arn       = module.monitor_snowflake_datastore_lambda_function.lambda_function_arn
}


resource "aws_lambda_permission" "allow_events_bridge_to_run_monitor_snowflake_datastore_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.monitor_snowflake_datastore_lambda_function.lambda_function_name
  principal     = "events.amazonaws.com"
}