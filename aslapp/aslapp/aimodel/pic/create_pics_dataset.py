import os
import pickle
import mediapipe as mp
import cv2
import matplotlib.pyplot as plt

# Initialize MediaPipe Hands solution
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles

hands = mp_hands.Hands(static_image_mode=True, min_detection_confidence=0.3)

# Directory for the data
DATA_DIR = './data'

data = []
labels = []

# Iterate through each class directory in DATA_DIR
for dir_ in os.listdir(DATA_DIR):
    class_dir = os.path.join(DATA_DIR, dir_)
    # Ensure that we're only processing directories (classes)
    if not os.path.isdir(class_dir):
        continue

    print(f'Processing class: {dir_}')

    # Iterate through each image in the class directory
    for img_path in os.listdir(class_dir):
        data_aux = []
        x_ = []
        y_ = []

        img = cv2.imread(os.path.join(class_dir, img_path))
        if img is None:
            print(f"Warning: Unable to read image at path {os.path.join(class_dir, img_path)}")
            continue

        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        # Process the image to extract hand landmarks
        results = hands.process(img_rgb)
        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                for i in range(len(hand_landmarks.landmark)):
                    x = hand_landmarks.landmark[i].x
                    y = hand_landmarks.landmark[i].y

                    x_.append(x)
                    y_.append(y)

                # Normalize landmarks to make them relative to the hand's bounding box
                for i in range(len(hand_landmarks.landmark)):
                    x = hand_landmarks.landmark[i].x
                    y = hand_landmarks.landmark[i].y
                    data_aux.append(x - min(x_))
                    data_aux.append(y - min(y_))

            # Append the processed data and labels
            data.append(data_aux)
            labels.append(dir_)

# Save the processed data and labels to a pickle file
with open('data.pickle', 'wb') as f:
    pickle.dump({'data': data, 'labels': labels}, f)

print("Dataset creation complete. Data saved to 'data.pickle'.")
