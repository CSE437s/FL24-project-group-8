from django.db import models
from django.contrib.auth.models import AbstractUser
from django.contrib.auth import get_user_model
from django.conf import settings
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    confirmation_token = models.CharField(max_length=32, blank=True, null=True)

<<<<<<< HEAD
User = get_user_model()
=======


User = get_user_model()

>>>>>>> main
class FriendRequest(models.Model):
    from_user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='sent_requests', on_delete=models.CASCADE)
    to_user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='received_requests', on_delete=models.CASCADE)
    timestamp = models.DateTimeField(auto_now_add=True)
    accepted = models.BooleanField(default=False)
<<<<<<< HEAD
    class Meta:
        unique_together = ('from_user', 'to_user')
        ordering = ['-timestamp']
    def __str__(self):
        return f"Friend request from {self.from_user.username} to {self.to_user.username}"
=======

    class Meta:
        unique_together = ('from_user', 'to_user')
        ordering = ['-timestamp']

    def __str__(self):
        return f"Friend request from {self.from_user.username} to {self.to_user.username}"

>>>>>>> main
class Friendship(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='friends', on_delete=models.CASCADE)
    friend = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='friends_of', on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
<<<<<<< HEAD
    class Meta:
        unique_together = ('user', 'friend')
    def __str__(self):
        return f"{self.user.username} is friends with {self.friend.username}"
=======

    class Meta:
        unique_together = ('user', 'friend')

    def __str__(self):
        return f"{self.user.username} is friends with {self.friend.username}"
>>>>>>> main
