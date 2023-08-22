from slack_sdk import WebClient
import os, requests

def sendSlackAlert():
    SLACK_BOT_TOKEN = os.environ['SLACK_BOT_TOKEN']
    slack_client = WebClient(SLACK_BOT_TOKEN)
    CHANNEL_NAME = os.environ["CHANNEL_NAME"]

    response = slack_client.chat_postMessage(
                channel=CHANNEL_NAME,
                text="Blackbox monitor for Datastore has failed!"
            )
    return response

def createOpsgenieIncident():
    response = requests.post(
        "https://api.opsgenie.com/v1/incidents/create",
        headers={
        "Content-Type": "application/json",
        "Authorization": f"GenieKey {os.environ['OPSGENIE_TOKEN']}"
        },
        data={
            "message": "Datastore not responding",
            "description":"Blackbox monitor for Datastore has failed!",
            "responders":[
                {"name":f"{os.environ['OPSGENIE_TEAM_NAME']}", "type":"team"}
            ]
        }
    )
    return response