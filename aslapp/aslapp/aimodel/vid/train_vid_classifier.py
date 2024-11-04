import pickle
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import numpy as np
import cv2
import os

# Load preprocessed data (assumes 'data' contains extracted features per video)
data_dict = pickle.load(open('./data.pickle', 'rb'))
data = np.asarray(data_dict['data'])  # Each entry corresponds to a video-level feature
labels = np.asarray(data_dict['labels'])

# Split data for training/testing
x_train, x_test, y_train, y_test = train_test_split(data, labels, test_size=0.2, shuffle=True, stratify=labels)

# Train RandomForest model
model = RandomForestClassifier()
model.fit(x_train, y_train)

# Predict on test set
y_predict = model.predict(x_test)
score = accuracy_score(y_predict, y_test)

print('{}% of samples were classified correctly!'.format(score * 100))

# Save model
with open('video_model.p', 'wb') as f:
    pickle.dump({'model': model}, f)
print("Model saved as 'video_model.p'")

# Function to extract features from video frames
def extract_video_features(video_path, frame_limit=50):
    cap = cv2.VideoCapture(video_path)
    frame_count = 0
    features = []

    while cap.isOpened() and frame_count < frame_limit:
        ret, frame = cap.read()
        if not ret:
            break
        # Resize and preprocess the frame if necessary
        frame_resized = cv2.resize(frame, (64, 64)).flatten()  # Example: resizing and flattening frame
        features.append(frame_resized)
        frame_count += 1

    cap.release()
    cv2.destroyAllWindows()
    
    # Aggregate frames into a single feature (e.g., averaging)
    if features:
        video_features = np.mean(features, axis=0)  # Average frames to create video-level feature
    else:
        video_features = np.zeros((64*64*3,))  # Fallback for empty video

    return video_features

# Example usage on a new video
video_path = './example_video.avi'
video_features = extract_video_features(video_path)
video_features = video_features.reshape(1, -1)  # Reshape for model input

# Classify the video
video_prediction = model.predict(video_features)
print(f'Predicted class for the video: {video_prediction[0]}')
