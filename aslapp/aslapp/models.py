import os
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.contrib.auth import get_user_model
from django.conf import settings
import pickle
import cv2
import sys
import mediapipe as mp
import numpy as np
from django.db import models
from tensorflow.keras.models import load_model
from rest_framework import serializers
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
        model_path = os.path.join(settings.BASE_DIR, 'aslapp', 'aimodel', 'model_pic.p')
        with open(model_path, 'rb') as model_file:
                model_dict = pickle.load(model_file)
                self.model = model_dict['model']
        # model_dict = pickle.load(open('aslapp/aslapp/aimodel/model_pic.p', 'rb'))
        # self.model = model_dict['model']

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

class PhrasePredictor:
    def __init__(self):
        model_path = os.path.join(settings.BASE_DIR, 'aslapp', 'aimodel', 'video_classification_lstm.h5')
        label_path = os.path.join(settings.BASE_DIR, 'aslapp', 'aimodel', 'label_encoder.pickle')

        self.model = load_model(model_path)

        with open(label_path, 'rb') as f:
            self.label_encoder = pickle.load(f)

        # Initialize MediaPipe Hands solution
        self.mp_hands = mp.solutions.hands
        self.mp_drawing = mp.solutions.drawing_utils
        self.mp_drawing_styles = mp.solutions.drawing_styles
        self.hands = self.mp_hands.Hands(static_image_mode=False, min_detection_confidence=0.3)

        # Parameters
        self.num_frames = 50  # The number of frames each video should have for the LSTM model
        self.num_landmarks = 21 * 2  # 21 hand landmarks with x, y coordinates


        # Define label mapping
        self.labels_dict = {0: 'Hello', 1: 'Thank You', 2: 'Nice To Meet You'}

    def extract_landmarks_from_video(self, video_path):
         # Open video file
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            print(f"Error: Could not open video {video_path}.")
            return None

        frame_landmarks = []  # Store landmark data for each frame

        while cap.isOpened() and len(frame_landmarks) < self.num_frames:
            ret, frame = cap.read()
            if not ret:
                break  # Exit if no more frames are available

            data_aux = []
            x_ = []
            y_ = []

            # Convert frame to RGB for MediaPipe processing
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = self.hands.process(frame_rgb)

            # Process detected hands and landmarks if available
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

                # Append the processed landmarks if they match expected size
                if len(data_aux) == self.num_landmarks:
                    frame_landmarks.append(data_aux)
                else:
                    # Append zero array if landmark size is inconsistent
                    frame_landmarks.append([0] * self.num_landmarks)
            else:
                # Append zero array if no hand is detected in the frame
                frame_landmarks.append([0] * self.num_landmarks)

        cap.release()

        # If there are fewer frames than required, pad with zero frames
        while len(frame_landmarks) < self.num_frames:
            frame_landmarks.append([0] * self.num_landmarks)

        # Trim to ensure the sequence has exactly `num_frames`
        frame_landmarks = frame_landmarks[:self.num_frames]
        return np.array(frame_landmarks)

    def predict_phrase_from_video(self, video_path):
        # Extract landmarks for the entire video
        video_landmarks = self.extract_landmarks_from_video(video_path)
        if video_landmarks is None:
            print("No valid hand landmarks detected in any frames.")
            return None

        # Reshape the data to match the LSTM model input (1, num_frames, num_landmarks)
        video_landmarks = video_landmarks.reshape(1, self.num_frames, self.num_landmarks)

        # Use the model to predict on the entire sequence
        prediction = self.model.predict(video_landmarks)
        predicted_label = self.label_encoder.inverse_transform([np.argmax(prediction)])[0]
        return self.labels_dict[int(predicted_label[0])]

class Video(models.Model):
    title = models.CharField(max_length=100)
    video_file = models.FileField(upload_to='videos/')
    upload_date = models.DateTimeField(auto_now_add=True)

class VideoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Video
        fields = ['id', 'title', 'video_file']