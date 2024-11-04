import pickle
import numpy as np
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout
from tensorflow.keras.utils import to_categorical
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# Load processed video data
data_dict = pickle.load(open('./data.pickle', 'rb'))

# Parameters
num_frames = 50  # Number of frames per video to use (trim or pad to this length)
num_landmarks = 21 * 2  # 21 landmarks with x, y coordinates

# Prepare data: reshaping each video to have a fixed number of frames
data = []
labels = []

for video_frames in data_dict['data']:
    video_frames = np.array(video_frames)
    
    # Trim or pad the video to have `num_frames`
    if video_frames.shape[0] > num_frames:
        video_frames = video_frames[:num_frames]
    elif video_frames.shape[0] < num_frames:
        padding = np.zeros((num_frames - video_frames.shape[0], num_landmarks))
        video_frames = np.vstack((video_frames, padding))
    
    data.append(video_frames)

# Convert data and labels to numpy arrays
data = np.array(data)  # Shape: (num_videos, num_frames, num_landmarks)
labels = np.array(data_dict['labels'])

# Encode labels as integers
label_encoder = LabelEncoder()
labels_encoded = label_encoder.fit_transform(labels)
labels_encoded = to_categorical(labels_encoded)  # One-hot encode for classification

# Train-test split
x_train, x_test, y_train, y_test = train_test_split(data, labels_encoded, test_size=0.2, stratify=labels)

# Define the LSTM model
model = Sequential([
    LSTM(64, input_shape=(num_frames, num_landmarks), return_sequences=True),
    Dropout(0.3),
    LSTM(64, return_sequences=False),
    Dropout(0.3),
    Dense(64, activation='relu'),
    Dense(labels_encoded.shape[1], activation='softmax')  # Output layer for classification
])

# Compile the model
model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

# Train the model
history = model.fit(x_train, y_train, epochs=30, batch_size=16, validation_data=(x_test, y_test))

# Evaluate the model on the test set
test_loss, test_accuracy = model.evaluate(x_test, y_test)
print(f"Test accuracy: {test_accuracy * 100:.2f}%")

# Save the trained model
model.save('video_classification_lstm.h5')

# Optional: save the label encoder to use for predictions
with open('label_encoder.pickle', 'wb') as f:
    pickle.dump(label_encoder, f)
