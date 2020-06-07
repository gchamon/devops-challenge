import falcon
import boto3
import os
import json


STORAGE_BUCKET = os.environ["STORAGE_BUCKET"]

s3_client = boto3.client("s3")


class TodoState(object):
    def on_get(self, request: falcon.Request, response: falcon.Response, state_name: str):
        try:
            object_response = s3_client.get_object(Bucket=STORAGE_BUCKET, Key=f"{state_name}.json")
            todo_list = json.loads(object_response["Body"].read())
            response.status = falcon.HTTP_200
            response.media = todo_list
        except Exception as e:
            response.media = {"cause": f"Cannot get state {state_name}: {str(e)}"}
            response.status = falcon.HTTP_404

    def on_put(self, request: falcon.Request, response: falcon.Response, state_name: str):
        try:
            state_content = request.media
            s3_client.put_object(Bucket=STORAGE_BUCKET,
                                 Key=f"{state_name}.json",
                                 Body=json.dumps(state_content).encode("utf-8"))
            response.status = falcon.HTTP_200
        except Exception as e:
            response.media = {"cause": f"Cannot get state {state_name}: {str(e)}"}
            response.status = falcon.HTTP_500
