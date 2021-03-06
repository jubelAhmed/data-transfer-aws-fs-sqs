

# it will create lambda function zip file
data "archive_file" "make_go_archive_main" {
  type        = "zip"
  source_file = "${path.module}./../lambda/firehose_and_sqs_controller/data_send_to_firehose_or_sqs/main"
  output_path = "${path.module}./../lambda/firehose_and_sqs_controller/data_send_to_firehose_or_sqs/main.zip"
}

# create a lambda function from zip file
resource "aws_lambda_function" "main" {

  filename      = "${path.module}./../lambda/firehose_and_sqs_controller/data_send_to_firehose_or_sqs/main.zip"
  function_name = "${var.sqs_fs_lambda_function_name}_${var.environment}"
  role          = aws_iam_role.lambda_firehsoe_s3_role.arn
  handler       = "main"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  # source_code_hash = filebase64sha256("${path.module}./../lambda/firehose_and_sqs_controller/data_send_to_firehose_or_sqs/main.zip")
  source_code_hash = "${data.archive_file.make_go_archive_main.output_base64sha256}"

  runtime = "go1.x"

  environment {
    variables = {
      delivery_stream_name = aws_kinesis_firehose_delivery_stream.extended_s3_stream.name,
      main_sqs_name = aws_sqs_queue.sqs_main.name,
      dead_letter_queue_name = aws_sqs_queue.terraform_queue_deadletter.name,
      region = var.region
    }
  }

}



data "archive_file" "make_go_archive_dlq" {
  type        = "zip"
  source_file = "${path.module}./../lambda/sqs/receive_msg_from_dlq/main"
  output_path = "${path.module}./../lambda/sqs/receive_msg_from_dlq/main.zip"
}

# this lambda function for receiving event from dead letter queue
resource "aws_lambda_function" "receive_msg_from_dlq" {

  filename      = "${path.module}./../lambda/sqs/receive_msg_from_dlq/main.zip"
  function_name = "${var.receive_dlq_lambda_function_name}_${var.environment}"
  role          = aws_iam_role.lambda_firehsoe_s3_role.arn
  handler       = "main"

  # source_code_hash = filebase64sha256("${path.module}./../lambda/sqs/receive_msg_from_dlq/main.zip")
  source_code_hash = "${data.archive_file.make_go_archive_dlq.output_base64sha256}"


  runtime = "go1.x"


}

data "archive_file" "kinesis_lambda_processor" {
  type        = "zip"
  source_file = "${path.module}./../lambda/firehose/kinesis_lambda_processor/main"
  output_path = "${path.module}./../lambda/firehose/kinesis_lambda_processor/main.zip"
}

# this lambda function for receiving event from dead letter queue
resource "aws_lambda_function" "kinesis_lambda_processor" {

  filename      = "${path.module}./../lambda/firehose/kinesis_lambda_processor/main.zip"
  function_name = "${var.kinesis_processor_lambda_function_name}_${var.environment}"
  role          = aws_iam_role.lambda_firehsoe_s3_role.arn
  handler       = "main"

  # source_code_hash = filebase64sha256("${path.module}./../lambda/sqs/receive_msg_from_dlq/main.zip")
  source_code_hash = "${data.archive_file.kinesis_lambda_processor.output_base64sha256}"


  runtime = "go1.x"


}


data "archive_file" "s3_event_for_metadata_add" {
  type        = "zip"
  source_file = "${path.module}./../lambda/s3/s3_event_for_metadata_and_checksum/main"
  output_path = "${path.module}./../lambda/s3/s3_event_for_metadata_and_checksum/main.zip"
}

# this lambda function for receiving event from dead letter queue
resource "aws_lambda_function" "s3_event_for_metadata_add" {

  filename      = "${path.module}./../lambda/s3/s3_event_for_metadata_and_checksum/main.zip"
  function_name = "${var.s3_event_function_name}"
  role          = aws_iam_role.lambda_firehsoe_s3_role.arn
  handler       = "main"

  # source_code_hash = filebase64sha256("${path.module}./../lambda/sqs/receive_msg_from_dlq/main.zip")
  source_code_hash = "${data.archive_file.s3_event_for_metadata_add.output_base64sha256}"


  runtime = "go1.x"


}


resource "aws_lambda_permission" "allow_bucket1" {
  statement_id  = "AllowExecutionFromS3Bucket1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_event_for_metadata_add.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}



