import json
import os

import boto3
import falcon

STORAGE_BUCKET = os.environ.get("STORAGE_BUCKET", None)


def put_in_s3(request, response, key):
    s3_client = boto3.client("s3")
    state_content = request.media
    s3_client.put_object(Bucket=STORAGE_BUCKET,
                         Key=key,
                         Body=json.dumps(state_content).encode("utf-8"))
    response.status = falcon.HTTP_200


def get_from_s3(response, key):
    s3_client = boto3.client("s3")
    object_response = s3_client.get_object(Bucket=STORAGE_BUCKET, Key=key)
    todo_list = json.loads(object_response["Body"].read())
    response.status = falcon.HTTP_200
    response.media = todo_list


def get_from_disc(filename, response):
    with open(filename) as file_to_load:
        response.media = json.load(file_to_load)
        response.status = falcon.HTTP_200


def put_in_disc(filename, request):
    with open(filename, "w") as file_to_save:
        json.dump(request.media, file_to_save)


class TodoState(object):
    def on_get(self, request: falcon.Request, response: falcon.Response, state_name: str):
        filename = f"{state_name}.json"
        try:
            if STORAGE_BUCKET:
                get_from_s3(response, filename)
            else:
                get_from_disc(filename, response)
        except Exception as e:
            response.media = {"cause": f"Cannot get state {filename}: {str(e)}"}
            response.status = falcon.HTTP_404

    def on_put(self, request: falcon.Request, response: falcon.Response, state_name: str):
        try:
            filename = f"{state_name}.json"
            if STORAGE_BUCKET:
                put_in_s3(request, response, filename)
            else:
                put_in_disc(filename, request)
        except Exception as e:
            response.media = {"cause": f"Cannot put state {filename}: {str(e)}"}
            response.status = falcon.HTTP_500
