import json
import os
import urllib.request

def lambda_handler(event, context):
    webhook_url = os.environ["DISCORD_WEBHOOK_URL"]

    detail_type = event.get("detail-type", "Unknown")
    detail = event.get("detail", {})

    message = {
        "content": f"🚀 Evento DevOps detectado: **{detail_type}**\nDetalhes: ```json\n{json.dumps(detail, indent=2)}\n```"
    }

    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(message).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )

    try:
        with urllib.request.urlopen(req) as response:
            return {"statusCode": response.getcode()}
    except Exception as e:
        return {"statusCode": 500, "body": str(e)}
