import os
import cv2

# Directory setup
DATA_DIR = './data'
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

number_of_classes = 3
videos_per_class = 30
video_duration_frames = 50  # Number of frames per video; adjust as needed

# Attempt to access the camera
cap = cv2.VideoCapture(0)  # Try with index 0 first; adjust to 1 or 2 if necessary

if not cap.isOpened():
    print("Error: Could not open video capture. Check camera connection and index.")
    exit()

# Loop through each class to collect videos
for j in range(number_of_classes):
    class_dir = os.path.join(DATA_DIR, str(j), "_vid")
    if not os.path.exists(class_dir):
        os.makedirs(class_dir)

    print(f'Preparing to collect video data for class {j}')

    for video_index in range(videos_per_class):
        print(f"Get ready to record video {video_index + 1}/{videos_per_class} for class {j}")

        # Wait for user readiness to start recording
        while True:
            ret, frame = cap.read()
            if not ret:
                print("Error: Failed to capture frame. Check camera connection.")
                break

            cv2.putText(frame, 'Press "S" to start recording', (100, 50), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2, cv2.LINE_AA)
            cv2.imshow('frame', frame)

            if cv2.waitKey(25) & 0xFF == ord('s'):  # Start recording on 's' press
                break

        # Setup video writer for each video
        video_path = os.path.join(class_dir, f'class_{j}_video_{video_index}.avi')
        fourcc = cv2.VideoWriter_fourcc(*'XVID')
        out = cv2.VideoWriter(video_path, fourcc, 20.0, (int(cap.get(3)), int(cap.get(4))))

        print(f"Recording video {video_index + 1} for class {j}. Press 'Q' to stop early or wait for {video_duration_frames} frames.")

        frame_count = 0
        while frame_count < video_duration_frames:  # Record for a set number of frames
            ret, frame = cap.read()
            if not ret:
                print("Error: Failed to capture frame. Stopping video recording.")
                break

            out.write(frame)
            cv2.imshow('frame', frame)
            frame_count += 1

            # Stop recording early if 'q' is pressed
            if cv2.waitKey(25) & 0xFF == ord('q'):
                print(f"Video recording {video_index + 1} for class {j} stopped by user.")
                break

        # Release the video writer for the current video
        out.release()
        print(f"Video {video_index + 1} saved at {video_path}")

# Release the capture and close windows
cap.release()
cv2.destroyAllWindows()
print("Video data collection completed.")
