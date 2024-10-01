# from rest_framework.response import Response
# from rest_framework.decorators import api_view
# from django.views.generic import TemplateView
# from .models import User  # Make sure to import your User model
# from django.shortcuts import render, get_object_or_404
# from django.http import JsonResponse
# from django.contrib.auth import get_user_model

# User = get_user_model() 
# @api_view(['GET'])
# def sample_view(request):
#     return Response({'message': 'Hello from Django!'})

# class ConfirmEmailView(TemplateView):
#     template_name = 'confirmation_success.html'  # Specify your template here

#     def get(self, request, *args, **kwargs):
#         token = kwargs.get('token')
#         user = get_object_or_404(User, confirmation_token=token)

#         if user:
#             user.is_active = True  # Activate the user account
#             user.confirmation_token = ''  # Clear the token
#             user.save()

#             return super().get(request, *args, **kwargs)  # Render success template
#         return JsonResponse({'detail': 'Invalid token'}, status=400)

# def confirm_email(request, token):
#     user = get_object_or_404(User, confirmation_token=token)

#     if user:
#         user.is_active = True
#         user.confirmation_token = ''
#         user.save()
#         return render(request, 'confirmation_success.html')  # Render your success template

#     return JsonResponse({'detail': 'Invalid token'}, status=400)

from django.contrib.auth import get_user_model
from django.contrib.sites.shortcuts import get_current_site
from django.core.mail import send_mail
from django.shortcuts import render
from django.urls import reverse
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.template.loader import render_to_string
from django.contrib.auth.tokens import default_token_generator
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.shortcuts import render
from django.http import JsonResponse
from django.contrib.sites.shortcuts import get_current_site
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.template.loader import render_to_string
from django.contrib.auth.tokens import default_token_generator
from django.views.decorators.csrf import csrf_exempt
import json
from django.conf import settings
from .token_generator import EmailConfirmationTokenGenerator

User = get_user_model()

def sample_view(request):
    return JsonResponse({"message": "This is a sample view."})

@csrf_exempt
def register(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            email = data['email']
            username = data['username']  # Assuming you also take username

            # Create the user (ensure you hash the password in a real app)
            user = User.objects.create_user(username=username, email=email)
            user.is_active = False  # Deactivate account until email is confirmed
            user.save()

            # Generate confirmation token
            token_generator = EmailConfirmationTokenGenerator()
            token = token_generator.make_token(user)

            # Send confirmation email
            verification_link = f"http://localhost:8000/auth/confirm-email/{token}/"
            subject = 'Email Confirmation'
            message = f'Thank you for registering! Please confirm your email by clicking this link: {verification_link}'
            from_email = settings.DEFAULT_FROM_EMAIL
            recipient_list = [email]

            send_mail(subject, message, from_email, recipient_list)

            return JsonResponse({"message": "User registered successfully. Verification email sent."}, status=201)
        except KeyError:
            return JsonResponse({"error": "Email and username are required."}, status=400)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON."}, status=400)

    return JsonResponse({"error": "Only POST requests are allowed."}, status=405)

def confirm_email(request, token):
    token_generator = EmailConfirmationTokenGenerator()
    user_id = token_generator.check_token(token)

    if user_id is not None:
        user = User.objects.get(id=user_id)
        user.is_active = True  # Activate the user
        user.save()
        return JsonResponse({"message": "Email confirmed successfully!"}, status=200)
    return JsonResponse({"error": "Invalid or expired token."}, status=400)

def activate(request, uidb64, token):
    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = User.objects.get(pk=uid)
        if default_token_generator.check_token(user, token):
            user.is_active = True
            user.save()
            login(request, user)  # Log the user in after activation
            return render(request, 'activation_success.html')
    except (TypeError, ValueError, OverflowError, User.DoesNotExist):
        user = None

    return render(request, 'activation_invalid.html')
