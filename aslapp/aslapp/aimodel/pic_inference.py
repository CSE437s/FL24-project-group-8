import pickle
import cv2
import mediapipe as mp
import numpy as np

# Load the pre-trained model
model_dict = pickle.load(open('./model.p', 'rb'))
model = model_dict['model']

# Initialize MediaPipe Hands solution
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles
hands = mp_hands.Hands(static_image_mode=True, min_detection_confidence=0.3)

# Define label mapping
labels_dict = {0: 'A', 1: 'B', 2: 'L'}

def predict_letter_from_image(image_path):
    data_aux = []
    x_ = []
    y_ = []

    # Read the image
    frame = cv2.imread(image_path)
    if frame is None:
        print(f"Error: Could not read the image from {image_path}.")
        return None

    # Get frame dimensions
    H, W, _ = frame.shape

    # Convert frame to RGB for MediaPipe processing
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(frame_rgb)

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
        prediction = model.predict([np.asarray(data_aux)])
        predicted_character = labels_dict[int(prediction[0])]
        return predicted_character

    else:
        print("No hands detected in the image.")
        return None

# Example usage
image_path = '/Users/jaspersands/Desktop/sign.jpg'  # Replace with the path to your image
predicted_character = predict_letter_from_image(image_path)
if predicted_character:
    print(f"The predicted character is: {predicted_character}")
