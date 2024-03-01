import os
import json
from datetime import datetime
from flask import Flask, request
from google.cloud import pubsub_v1

app = Flask(__name__)

# Set your Google Cloud project and Pub/Sub topic
project_id = os.environ.get('GCP_PROJECT')
topic_name = os.environ.get('GCP_TOPIC')

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_name)

@app.route('/v1/history', methods=['POST'])
def receive_webhoogk():
    try:
        payload = request.get_data(as_text=True)
        process_payload(payload)
        return "Webhook received successfully", 200
    except Exception as e:
        return f"Error processing webhook: {str(e)}", 500

def process_payload(payload):
    for line in payload.splitlines():
        try:
            data = json.loads(line)
            data["ts"] = datetime.utcfromtimestamp(data["clock"]).strftime('%Y-%m-%d %H:%M:%S')
            publish_to_pubsub(data)
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON: {str(e)}")
        except Exception as e:
            print(f"data: {json.dumps(data).encode('utf-8')}")
            print(f"Error processing payload: {str(e)}")

def publish_to_pubsub(data):
    data_str = json.dumps(data).encode('utf-8')
    future = publisher.publish(topic_path, data=data_str)
    print(f"Published message to Pub/Sub: {future.result()}")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
