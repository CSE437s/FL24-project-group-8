import mimetypes

class SetContentTypeMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        if response.get('Content-Type') is None and request.path.startswith('/static/'):
            mimetype, _ = mimetypes.guess_type(request.path)
            if mimetype:
                response['Content-Type'] = mimetype
        return response
