import jwt
from django.conf import settings

class EmailConfirmationTokenGenerator:
    def make_token(self, user):
        return jwt.encode({'user_id': user.id}, settings.SECRET_KEY, algorithm='HS256')

    def check_token(self, token):
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
            return payload['user_id']
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None