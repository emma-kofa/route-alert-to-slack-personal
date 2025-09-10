# route-alert-to-slack-personal
Personal Implementation of routing of the alert to slack with Terraform and AWS IoT Core


1. zip lambda.zip lambda_function.py
2. terraform init
3. terraform apply -var="slack_webhook_url=https://hooks.slack.com/services/XXX/YYY/ZZZ" -auto-approve
4. aws iot-data publish \
  --topic "sensors/alerts" \
  --payload fileb://payload.json

# emma.tt 


