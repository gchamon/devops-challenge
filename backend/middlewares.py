import falcon


class RequireJSON(object):

    def process_request(self, request, response):
        if not request.client_accepts_json:
            raise falcon.HTTPNotAcceptable('This API only supports responses encoded as JSON.',
                                           href='https://github.com/lettdigital/onepassword-service#1password-api-1')

        if (request.method in ('POST', 'PUT')
                and 'application/json' not in request.content_type):
            raise falcon.HTTPUnsupportedMediaType('This API only supports requests encoded as JSON.',
                                                  href='https://github.com/lettdigital/onepassword-service#1password-api-1')
