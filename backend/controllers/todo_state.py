import falcon
import boto3

s3_client = boto3.client("s3")


class TodoState(object):
    def on_get(self, request: falcon.Request, response: falcon.Response, state_name: str):
        response.status = falcon.HTTP_200

    def on_put(self, request: falcon.Request, response: falcon.Response, state_name: str):
        response.status = falcon.HTTP_200
