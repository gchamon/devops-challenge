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


class CORSComponent(object):
    def process_response(self, req, resp, resource, req_succeeded):
        resp.set_header('Access-Control-Allow-Origin', '*')

        if (req_succeeded
                and req.method == 'OPTIONS'
                and req.get_header('Access-Control-Request-Method')
        ):
            # NOTE(kgriffs): This is a CORS preflight request. Patch the
            #   response accordingly.

            allow = resp.get_header('Allow')
            resp.delete_header('Allow')

            allow_headers = req.get_header(
                'Access-Control-Request-Headers',
                default='*'
            )

            resp.set_headers((
                ('Access-Control-Allow-Methods', allow),
                ('Access-Control-Allow-Headers', allow_headers),
                ('Access-Control-Max-Age', '86400'),  # 24 hours
            ))
