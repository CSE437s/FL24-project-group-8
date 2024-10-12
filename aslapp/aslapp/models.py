from django.db import models
from django.contrib.auth.models import AbstractUser
from django.contrib.auth import get_user_model
from django.conf import settings
import pickle
import cv2
import mediapipe as mp
import numpy as np
from django.db import models

class User(AbstractUser):
    confirmation_token = models.CharField(max_length=32, blank=True, null=True)

# Get the custom user model
User = get_user_model()

class FriendRequest(models.Model):
    from_user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='sent_requests', on_delete=models.CASCADE)
    to_user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='received_requests', on_delete=models.CASCADE)
    timestamp = models.DateTimeField(auto_now_add=True)
    accepted = models.BooleanField(default=False)

    class Meta:
        unique_together = ('from_user', 'to_user')
        ordering = ['-timestamp']

    def __str__(self):
        return f"Friend request from {self.from_user.username} to {self.to_user.username}"

class Friendship(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='friends', on_delete=models.CASCADE)
    friend = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='friends_of', on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'friend')

    def __str__(self):
        return f"{self.user.username} is friends with {self.friend.username}"


class LetterPredictor:
    def __init__(self):
        # Load the pre-trained model
        model_dict = pickle.load(open('/Users/ryandickerson/Desktop/WUBER/FL24-project-group-8/aslapp/aslapp/aimodel/model.p', 'rb'))
        self.model = model_dict['model']

        # Initialize MediaPipe Hands solution
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(static_image_mode=True, min_detection_confidence=0.3)

        # Define label mapping
        self.labels_dict = {0: 'A', 1: 'B', 2: 'L'}

    def predict_letter_from_image(self, image_path):
        data_aux = []
        x_ = []
        y_ = []

        # Read the image
        frame = cv2.imread(image_path)
        if frame is None:
            print(f"Error: Could not read the image from {image_path}.")
            return None

        # Convert frame to RGB for MediaPipe processing
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.hands.process(frame_rgb)

        # Process detected hands and landmarks
        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                # Extract hand landmarks and calculate relative positions
                for i in range(len(hand_landmarks.landmark)):
                    x = hand_landmarks.landmark[i].x
                    y = hand_landmarks.landmark[i].y
                    x_.append(x)
                    y_.append(y)

                # Normalize coordinates relative to the bounding box of the hand
                for i in range(len(hand_landmarks.landmark)):
                    x = hand_landmarks.landmark[i].x
                    y = hand_landmarks.landmark[i].y
                    data_aux.append(x - min(x_))
                    data_aux.append(y - min(y_))

            # Make a prediction using the trained model
            prediction = self.model.predict([np.asarray(data_aux)])
            predicted_character = self.labels_dict[int(prediction[0])]
            return predicted_character

        else:
            print("No hands detected in the image.")
            return None  # Added return None for clarity

