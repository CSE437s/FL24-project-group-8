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

urlpatterns = [
    path('auth/register/', register, name='register'),
    path('auth/activate/<uidb64>/<token>/', activate, name='activate'),
    path('auth/confirm-email/<str:token>/', confirm_email, name='confirm_email'),
    path('auth/login/', login_view, name='login'),
    path('auth/password-reset/', request_password_reset, name='password_reset'),
    path('auth/password-reset-confirm/<uidb64>/<token>/', password_reset_confirm, name='password_reset_confirm'),
]


