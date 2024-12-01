"""
URL configuration for aslapp project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from django.urls import path, include
from .views import sample_view
from dj_rest_auth.registration.views import VerifyEmailView, RegisterView
from django.urls import path
from .views import register, activate  # Ensure this line is correct
from dj_rest_auth.registration.views import VerifyEmailView
from .views import register, confirm_email, login_view
from django.urls import path
from .views import request_password_reset, password_reset_confirm
from . import views
from .views import predict_letter_view
from .views import predict_phrase_view
from .views import daily_video_view
from . import views
from .views import get_video_name
from .views import upload_video_to_folder_view
from . import views
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve
from .views import serve_video
urlpatterns = [
    path('auth/register/', register, name='register'),
    path('auth/activate/<uidb64>/<token>/', activate, name='activate'),
    path('auth/confirm-email/<str:token>/', confirm_email, name='confirm_email'),
    path('auth/login/', login_view, name='login'),
    path('auth/password-reset/', request_password_reset, name='password_reset'),
    path('auth/password-reset-confirm/<uidb64>/<token>/', password_reset_confirm, name='password_reset_confirm'),
    path('friend-request/send/', views.send_friend_request, name='send_friend_request'),
    path('friend-request/accept/', views.accept_friend_request, name='accept_friend_request'),
    path('friend-request/list/', views.get_friend_requests, name='get_friend_requests'),
    path('friends/list/', views.get_friends_list, name='get_friends_list'),
    path('predict-letter/', predict_letter_view, name='predict_letter'),
    path('predict-phrase/', predict_phrase_view, name='predict_phrase'),
    path('daily-video/', daily_video_view, name='daily_video'),
    path('upload-video/', views.upload_video_view, name='upload_video'),
    path('get-video-name/', get_video_name, name='get_video_name'),
    path('upload-video-to-folder/', views.upload_video_to_folder_view, name='upload_video_to_folder'),
    path('get-all-folders/', views.get_all_folders_view, name='get_all_folders'),
    path('get-videos-from-folder/<str:folder_name>/', views.get_videos_from_folder_view, name='get_videos_from_folder'),
    path('user/update-points/', views.update_points, name='update_points'),
    path('user/update-streak/', views.update_streak, name='update_streak'),
    path('user/get-points/', views.get_points, name='get_points'),
    path('user/get-streak/', views.get_streak, name='get_streak'),
    path("static/<str:folder_name>/<str:video_name>", serve_video, name="serve_video"),
 ]

if settings.DEBUG:
    urlpatterns += [
        path('static/<path:path>', serve, {
            'document_root': settings.STATICFILES_DIRS[0],
        }),
    ]

