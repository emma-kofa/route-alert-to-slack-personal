import os
import json
import boto3
import urllib3

http = urllib3.PoolManager()

def get_slack_webhook():
    secret_name = os.environ["SECRET_NAME"]
    region_name = os.environ["REGION"]

    client = boto3.client("secretsmanager", region_name=region_name)
    secret_value = client.get_secret_value(SecretId=secret_name)
    return secret_value["SecretString"]

def lambda_handler(event, context):
    webhook_url = get_slack_webhook()

    message = {
        "text": f"IoT Alert Received:\n```{json.dumps(event, indent=2)}```"
    }

    encoded_msg = json.dumps(message).encode("utf-8")
    resp = http.request("POST", webhook_url, body=encoded_msg, headers={"Content-Type": "application/json"})

    print(f"Slack response: {resp.status}, {resp.data.decode('utf-8')}")
    return {"status": "Message sent to Slack"}

