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
from django.contrib.auth import authenticate, login
from django.shortcuts import render
from django.utils.http import urlsafe_base64_decode
from django.utils.encoding import force_str
from django.contrib.auth.tokens import default_token_generator
from django.http import JsonResponse
from django.contrib.auth import get_user_model
from django.http import JsonResponse
from django.contrib.auth import get_user_model
from django.views.decorators.csrf import csrf_exempt
import json
from .models import FriendRequest, Friendship
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from .models import FriendRequest
from django.views.decorators.csrf import csrf_exempt

User = get_user_model()

@csrf_exempt
def request_password_reset(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            email = data.get('email')

            if not email:
                return JsonResponse({"error": "Email is required."}, status=400)

            # Filter users by email (instead of get to avoid MultipleObjectsReturned)
            users = User.objects.filter(email=email)

            if not users.exists():
                return JsonResponse({"error": "User with this email does not exist."}, status=404)

            # For now, let's handle the first user with this email
            user = users.first()

            # Generate password reset token
            token = default_token_generator.make_token(user)
            uid = urlsafe_base64_encode(force_bytes(user.pk))

            # Create password reset link
            reset_link = f"http://localhost:8000/auth/password-reset-confirm/{uid}/{token}/"
            subject = 'Password Reset'
            message = f'Click the link to reset your password: {reset_link}'
            from_email = settings.DEFAULT_FROM_EMAIL
            recipient_list = [email]

            send_mail(subject, message, from_email, recipient_list)

            return JsonResponse({"message": "Password reset email sent."}, status=200)

        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON."}, status=400)

    return JsonResponse({"error": "Only POST requests are allowed."}, status=405)


@csrf_exempt
def password_reset_confirm(request, uidb64, token):
    if request.method == 'GET':
        # Serve the password reset form page for GET request
        return render(request, 'password_reset_form.html', {
            'uidb64': uidb64,
            'token': token
        })

    if request.method == 'POST':
        # Check if form data (not JSON) was submitted
        if request.content_type == 'application/json':
            try:
                data = json.loads(request.body)
                new_password = data.get('new_password')
            except json.JSONDecodeError:
                return JsonResponse({"error": "Invalid JSON."}, status=400)
        else:
            # Handle form data
            new_password = request.POST.get('new_password')

        if not new_password:
            return JsonResponse({"error": "New password is required."}, status=400)

        # Decode the user id
        try:
            uid = force_str(urlsafe_base64_decode(uidb64))
            user = User.objects.get(pk=uid)
        except (User.DoesNotExist, ValueError, TypeError, OverflowError):
            return JsonResponse({"error": "Invalid user."}, status=400)

        # Check the token
        if not default_token_generator.check_token(user, token):
            return JsonResponse({"error": "Invalid or expired token."}, status=400)

        # Set the new password
        user.set_password(new_password)
        user.save()

        return JsonResponse({"message": "Password reset successful."}, status=200)

    return JsonResponse({"error": "Only POST requests are allowed."}, status=405)

def sample_view(request):
    return JsonResponse({"message": "This is a sample view."})

@csrf_exempt
def login_view(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data['username']
            password = data['password']

            # Authenticate user
            user = authenticate(request, username=username, password=password)
            if user is not None:
                if user.is_active:
                    login(request, user)  # Log the user in
                    return JsonResponse({"message": "Login successful."}, status=200)
                else:
                    return JsonResponse({"error": "Account is inactive."}, status=403)
            else:
                return JsonResponse({"error": "Invalid credentials."}, status=400)
        except KeyError:
            return JsonResponse({"error": "Username and password are required."}, status=400)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON."}, status=400)

    return JsonResponse({"error": "Only POST requests are allowed."}, status=405)

@csrf_exempt
def register(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            email = data['email']
            username = data['username']  # Assuming you also take username
            password = data['password']
            # Create the user (ensure you hash the password in a real app)
            user = User.objects.create_user(username=username, email=email, password=password)
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
        User = get_user_model()  # Get the user model
        try:
            user = User.objects.get(id=user_id)
            if not user.is_active:  # Only activate if not already active
                user.is_active = True
                user.save()
                return JsonResponse({"message": "Email confirmed successfully!"}, status=200)
            else:
                return JsonResponse({"message": "Email already confirmed."}, status=200)  # User already active
        except ObjectDoesNotExist:
            return JsonResponse({"error": "User does not exist."}, status=404)
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

@csrf_exempt  # Use with caution, only if you understand the implications
def send_friend_request(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            from_username = data.get('from_username')
            to_username = data.get('to_username')

            # Validate that both usernames are provided
            if not from_username or not to_username:
                return JsonResponse({"error": "Both from_username and to_username are required."}, status=400)

            # Retrieve user instances
            from_user = User.objects.get(username=from_username)
            to_user = User.objects.get(username=to_username)

            # Create and save the friend request
            friend_request = FriendRequest(from_user=from_user, to_user=to_user)
            friend_request.save()

            return JsonResponse({"message": "Friend request sent successfully!"}, status=200)
        except User.DoesNotExist:
            return JsonResponse({"error": "User not found."}, status=404)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON."}, status=400)
    return JsonResponse({"error": "Invalid request method."}, status=400)

@csrf_exempt
def accept_friend_request(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            from_username = data['from_username']
            to_username = data['to_username']

            from_user = User.objects.get(username=from_username)
            to_user = User.objects.get(username=to_username)

            friend_request = FriendRequest.objects.get(from_user=from_user, to_user=to_user)

            if friend_request.accepted:
                return JsonResponse({"error": "Friend request already accepted."}, status=400)

            friend_request.accepted = True
            friend_request.save()

            # Create mutual friendships
            Friendship.objects.create(user=from_user, friend=to_user)
            Friendship.objects.create(user=to_user, friend=from_user)

            return JsonResponse({"message": "Friend request accepted."}, status=200)
        except KeyError:
            return JsonResponse({"error": "Both from_username and to_username are required."}, status=400)
        except FriendRequest.DoesNotExist:
            return JsonResponse({"error": "Friend request not found."}, status=404)
        except User.DoesNotExist:
            return JsonResponse({"error": "User not found."}, status=404)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON format."}, status=400)

    return JsonResponse({"error": "Only POST requests are allowed."}, status=405)

@csrf_exempt
def get_friend_requests(request):
    if request.method == 'GET':
        # Get the logged-in user
        user = request.user

        # Get sent friend requests
        sent_requests = FriendRequest.objects.filter(from_user=user)
        sent_list = [
            {
                "to_user": fr.to_user.username,
                "timestamp": fr.timestamp,
                "accepted": fr.accepted
            }
            for fr in sent_requests
        ]

        # Get received friend requests
        received_requests = FriendRequest.objects.filter(to_user=user)
        received_list = [
            {
                "from_user": fr.from_user.username,
                "timestamp": fr.timestamp,
                "accepted": fr.accepted
            }
            for fr in received_requests
        ]

        # Return JSON response with both lists
        return JsonResponse({
            "sent_requests": sent_list,
            "received_requests": received_list
        }, status=200)

    return JsonResponse({"error": "Only GET requests are allowed."}, status=405)

@csrf_exempt  # Use with caution
def get_friends_list(request):
    if request.method == 'GET':
        username = request.GET.get('username')
        
        if not username:
            return JsonResponse({"error": "Username is required."}, status=400)

        try:
            user = User.objects.get(username=username)
            friends = user.friends.values('friend__username')  # Adjust as needed for your data structure

            return JsonResponse({"friends": list(friends)}, status=200)
        except User.DoesNotExist:
            return JsonResponse({"error": "User not found."}, status=404)
    
    return JsonResponse({"error": "Invalid request method."}, status=400)
