import os
import pickle
import mediapipe as mp
import cv2

# Initialize MediaPipe Hands solution
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles

hands = mp_hands.Hands(static_image_mode=False, min_detection_confidence=0.3)

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

    # Iterate through each video in the class directory
    for video_path in os.listdir(class_dir):
        video_file_path = os.path.join(class_dir, video_path)
        
        # Open the video file
        cap = cv2.VideoCapture(video_file_path)
        if not cap.isOpened():
            print(f"Warning: Unable to open video at path {video_file_path}")
            continue

        data_aux = []
        frame_count = 0  # Keep track of frames processed per video

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break  # Stop if there are no more frames to read

            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            # Process the frame to extract hand landmarks
            results = hands.process(frame_rgb)
            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    x_ = []
                    y_ = []

                    # Collect all landmark coordinates
                    for i in range(len(hand_landmarks.landmark)):
                        x = hand_landmarks.landmark[i].x
                        y = hand_landmarks.landmark[i].y
                        x_.append(x)
                        y_.append(y)

                    # Normalize landmarks to make them relative to the hand's bounding box
                    frame_data = []
                    for i in range(len(hand_landmarks.landmark)):
                        x = hand_landmarks.landmark[i].x
                        y = hand_landmarks.landmark[i].y
                        frame_data.append(x - min(x_))
                        frame_data.append(y - min(y_))

                    data_aux.append(frame_data)  # Add frame's landmark data to video data

            frame_count += 1
            if frame_count > 50:  # Limit frames per video to reduce processing time
                break

        # Append the processed data and label for the entire video
        if data_aux:  # Only save if we captured any landmarks
            data.append(data_aux)
            labels.append(dir_)

        cap.release()  # Release video capture object for the current video
        print(f"Finished processing video {video_path} for class {dir_}")

# Save the processed data and labels to a pickle file
with open('data.pickle', 'wb') as f:
    pickle.dump({'data': data, 'labels': labels}, f)

print("Dataset creation complete. Data saved to 'data.pickle'.")
