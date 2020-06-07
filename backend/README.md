# 1Password API

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=lettdigital_onepassword-service&metric=alert_status)](https://sonarcloud.io/dashboard?id=lettdigital_onepassword-service)

A complete stack of service integration with 1Password, implemented using [falcon](https://falcon.readthedocs.io/en/stable/) framework

## Requirements

* python 3.7+

* pipenv

## Configuration

### Lambda function

Environment variables:

| Variable | Default  | Description  |
|---|---|---|
| `ONEPASSWORD_API_URL`  | "http://localhost"  | The url of the onepassword api  |
| `ONEPASSWORD_KEYS_VAULT`  | "test"  | The vault in which to store or delete documents  |
| `SECRET_NAME`  | "lambda/prod/onepassword-credentials"  | The secret in AWS Secrets Manager that holds the onepassword credentials |
| `AWS_REGION`  | "us-east-1"  | The AWS Region  |

### 1Password API

You are able to change the port used by the api altering the file `docker-compose.yml`. Say you want to expose the API through the port 8080. Change the line `- "80:80"` under `nginx` to `- "8080:80"`.

## 1Password API

### Running

* `docker-compose up --detach`

* `docker-compose logs -f` (optional)

### Routes

#### Logging In:

You can either pass secrets each time you do an operation, or use the login route.

```shell script
curl --request POST \
  --url http://localhost/login \
  --header 'content-type: application/json' \
  --data '{
  "onepassword": {
    "secret": {
        "password": "<YOUR_PASSWORD>",
        "signin_address": "https://<YOUR_ORGANIZATION>.1password.com/",
        "username": "<YOUR_USERNAME>",
        "secret_key": "<YOUR_SECRET_KEY>"
    }
  }
}
'
```

* Returns:

```json
{
  "shorthand": "4t326a57-c771-4c11-9724-3e7cfeba98cb",
  "token": "VrTVbJ56swqxQl1gtCM3oclgbSvpy32QsrDMstcCcs9"
}
```

The return value can then be used in the field `onepassword`, instead of `secret`.

#### Listing resources

```shell script
curl --request GET \
  --url http://localhost/list/documents \
  --header 'content-type: application/json' \
  --data '{
  "onepassword": {
      "shorthand": "4t326a57-c771-4c11-9724-3e7cfeba98cb",
      "token": "VrTVbJ56swqxQl1gtCM3oclgbSvpy32QsrDMstcCcs9"
  }
}'
```

Where `${RESOURCE}` must be one of:
```
  documents   Get a list of documents.
  events      Get a list of events from the Activity Log.
  groups      Get the list of groups.
  items       Get a list of items.
  templates   Get the list of templates.
  users       Get the list of users.
  vaults      Get the list of vaults.
```

#### Getting a resource

```shell script
curl --request GET \
  --url http://localhost/${RESOURCE}/${ITEM} \
  --header 'content-type: application/json' \
  --data '{
  "onepassword": {
      "shorthand": "4t326a57-c771-4c11-9724-3e7cfeba98cb",
      "token": "VrTVbJ56swqxQl1gtCM3oclgbSvpy32QsrDMstcCcs9"
  }
}'
```

`${RESOURCE}` is as in `Listing resources`. `${ITEM}` can be a UUID or name.

* Returns the contents of the file in the response.

#### Creating a document

```shell script
curl --request POST \
  --url http://localhost/documents \
  --header 'content-type: application/json' \
  --data '{
	"items": [
		{
			"name": "test",
			"vault": "test",
			"contents": "test"
		}
	],
	"onepassword": {
		"secret": {
			"password": "<YOUR_PASSWORD>",
			"signin_address": "https://<YOUR_ORGANIZATION>.1password.com/",
			"username": "<YOUR_USERNAME>",
			"secret_key": "<YOUR_SECRET_KEY>"
		}
	}
}'
```

Returns:
```json
[
    {
        "shorthand": "cxss255hhxaiatfsdsiyyah4m1",
        "createdAt": "2020-02-03T19:44:49.277584271Z",
        "updatedAt": "2020-02-03T19:44:49.277584916Z",
        "vaultUuid": "gkkjsqm73s7vpnxb1js4lragh1"
    }
]
```

#### Deleting items

```shell script
curl --request DELETE \
  --url http://localhost/items \
  --header 'content-type: application/json' \
  --data '{
	"items": [
		{
			"name": "test",
			"vault": "test"
		}
	],
	"onepassword": {
		"secret": {
			"password": "<YOUR_PASSWORD>",
			"signin_address": "https://<YOUR_ORGANIZATION>.1password.com/",
			"username": "<YOUR_USERNAME>",
			"secret_key": "<YOUR_SECRET_KEY>"
		}
	}
}'
```

Return codes depend on the individual deletions:

* if all went well, a 204 code is returned.

* if all items weren't found, a 404 code is returned.

* if some items weren't deleted, a 207 code is returned along a list of item names and individual result messages.

    * some failed
    
    * some weren't found
    
    * some had multiple UUIDs associated with the same name, in which case the list of uuids is returned

* if all failed, a 422 code is returned with a list of item names and results.

possible response body:
```json
{
    "item": string,
    "result": "not found" | "fail" | "ok" | {"multiple_uuids": string[]},
}[]
```

### Testing the Lambda function

With the api running:

* `pipenv shell`

* `cd aws-lambda`

* configure the correct environment variable as in Configuration > Lambda function

* configure two extra environment variables, respectively TEST_BUCKET and TEST_OBJECT to point to real bucket and object for testing

* python3 test.py

## Features

### 1Password
* One time or every time login

* List and get resources

* Create documents

* Delete items

### AWS Lambda
* Read 1Password credentials from AWS Secrets Manager

* S3 deletion/creation handling

## Integration workflow

1. S3 triggers `ObjectCreated` or `ObjectRemoved` event;

2. The lambda function passes the contents and filenames of the created objects to the onepassword api;

3. The onepassword api logs in with the credentials provided in the requests and proceedes to add/remove items. The results are sent back to the lambda function;

3.1 In case of creation, the uuids of the created documents are returned;

3.2 In case of deletion, a 204 is returned on full success. A 200 is returned alongside a list of `ok`s and `fail`s for the respective files (in order which they were sent to the api). A 404 is sent when all items fail.

## 1Password API

### **POST** `/documents`

#### Request body (`application/json`)

##### Format:

* `items`: (required) a list of items to insert in 1Password as documents

    * `name`: (required) name of the document to create
    
    * `vault`: (required) vault to upload the document to
    
    * `title`: (optional) the title of the document. When not provided, falls back to the item name
    
    * `contents` (required) what will be written to the document
    
* `onepassword`:

    * `secret`:
   
        * `username`: (required) username to use to login to 1password
    
        * `password`: (required) the user password
        
        * `signin_address`: (required) the url of the 1password for the organization
        
        * `secret_key`: (required) the secret key provided by onepassword when creating the account. Can be retrieved by going to the user's "My Profile" page.

##### Example:
```json
{
    "items": [{
        "name": "example",
        "vault": "exampleVault",
        "title": "exampleTitle",
        "contents": "lorem ipsum dolem"
    }],
    "onepassword": {
        "secret": {
            "username": "programatic_access@myorganization.com",
            "password": "123456",
            "signin_address": "https://myorganization.1password.com/",
            "secret_key": "A1-75G3RF-85RT1T-45K23-M3CVJ-4782M-12345"
        }
    }
}
```

### **DELETE** `/items`

#### Request body (`application/json`)

##### Format:

* `items`: (required) a list of items to delete from 1password

    * `name`: (required) name of the document to create
    
    * `vault`: (required) vault to upload the document to
    
* `onepassword`:

    * `secret`:
   
        * `username`: (required) username to use to login to 1password
    
        * `password`: (required) the user password
        
        * `signin_address`: (required) the url of the 1password for the organization
        
        * `secret_key`: (required) the secret key provided by onepassword when creating the account. Can be retrieved by going to the user's "My Profile" page.

##### Example:
```json
{
    "items": [{
        "name": "example",
        "vault": "exampleVault"
    }],
    "onepassword": {
        "secret": {
            "username": "programatic_access@myorganization.com",
            "password": "123456",
            "signin_address": "https://myorganization.1password.com/",
            "secret_key": "A1-75G3RF-85RT1T-45K23-M3CVJ-4782M-12345"
        }
    }
}
```

## Deploying

The `docker-compose.yml` and `Dockerfile` provides a production-ready environment, using `gunicorn`, and exposing the API through an `nginx` container.

When deploying to an EC2, all you have to do is start the service using `docker-compose` in detached mode (as shown in `Testng > 1Password API`) and make sure the security group permits access to port 80. Put a load balancer or another nginx on the host for providing HTTPS.

The lambda function can be deployed by packing the contents of `aws-lambda` into a zip archive and uploading to the lambda function.

Necessary permissions for the lambda are:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "<MY_SECRETSMANAGER_SECRET_ARN>"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "<MY_BUCKET_ARN>/*"
        }
    ]
}
```

## Considerations

This API uses request body in GET requests. For a long time this was prohibited in RFC2616 HTTP specification,
but since RFCs 7230-7237, it is only discouraged, since older implementations could reject such requests.
However, given that major APIs such as ElasticSearch's already implement GET with request bodies, there is
precedence to such implementation.

Nonetheless, if this gives people headache, this implementation can be reconsidered. Keep in mind, this API
is being tested under the latest NGINX version and showed no problems whatsoever. It could present challanges
under specific load balancer implementations, but none has been so far encountered. 
