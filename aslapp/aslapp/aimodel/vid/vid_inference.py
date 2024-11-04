import pickle
import cv2
import sys
import mediapipe as mp
import numpy as np
from tensorflow.keras.models import load_model

# Load the pre-trained LSTM model and label encoder
model = load_model('video_classification_lstm.h5')
with open('label_encoder.pickle', 'rb') as f:
    label_encoder = pickle.load(f)

# Initialize MediaPipe Hands solution
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles
hands = mp_hands.Hands(static_image_mode=False, min_detection_confidence=0.3)

# Parameters
num_frames = 50  # The number of frames each video should have for the LSTM model
num_landmarks = 21 * 2  # 21 hand landmarks with x, y coordinates

def extract_landmarks_from_video(video_path):
    # Open video file
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"Error: Could not open video {video_path}.")
        return None

    frame_landmarks = []  # Store landmark data for each frame

    while cap.isOpened() and len(frame_landmarks) < num_frames:
        ret, frame = cap.read()
        if not ret:
            break  # Exit if no more frames are available

        data_aux = []
        x_ = []
        y_ = []

        # Convert frame to RGB for MediaPipe processing
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = hands.process(frame_rgb)

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
            if len(data_aux) == num_landmarks:
                frame_landmarks.append(data_aux)
            else:
                # Append zero array if landmark size is inconsistent
                frame_landmarks.append([0] * num_landmarks)
        else:
            # Append zero array if no hand is detected in the frame
            frame_landmarks.append([0] * num_landmarks)

    cap.release()

    # If there are fewer frames than required, pad with zero frames
    while len(frame_landmarks) < num_frames:
        frame_landmarks.append([0] * num_landmarks)

    # Trim to ensure the sequence has exactly `num_frames`
    frame_landmarks = frame_landmarks[:num_frames]
    return np.array(frame_landmarks)



def predict_letter_from_video(video_path):
    # Extract landmarks for the entire video
    video_landmarks = extract_landmarks_from_video(video_path)
    if video_landmarks is None:
        print("No valid hand landmarks detected in any frames.")
        return None

    # Reshape the data to match the LSTM model input (1, num_frames, num_landmarks)
    video_landmarks = video_landmarks.reshape(1, num_frames, num_landmarks)

    # Use the model to predict on the entire sequence
    prediction = model.predict(video_landmarks)
    predicted_label = label_encoder.inverse_transform([np.argmax(prediction)])[0]
    return predicted_label

# Example usage
video_path = sys.argv[1]  # Replace with the path to your video
predicted_character = predict_letter_from_video(video_path)
if predicted_character:
    if predicted_character == 0:
        print(f"The predicted character for the video is: {predicted_character}")
    print(f"The predicted character for the video is: {predicted_character}")
