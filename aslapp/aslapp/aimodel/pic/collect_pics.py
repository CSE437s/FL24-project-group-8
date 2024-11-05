import os
import cv2

# Directory setup
DATA_DIR = './data'
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

number_of_classes = 3
dataset_size = 100

# Attempt to access the camera
cap = cv2.VideoCapture(0)  # Try with index 0 first; adjust to 1 or 2 if necessary

if not cap.isOpened():
    print("Error: Could not open video capture. Check camera connection and index.")
    exit()

# Loop through the classes to collect data
for j in range(number_of_classes):
    class_dir = os.path.join(DATA_DIR, str(j))
    if not os.path.exists(class_dir):
        os.makedirs(class_dir)

    print(f'Collecting data for class {j}')

    # Wait for user readiness
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Error: Failed to capture frame. Check camera connection.")
            break

        cv2.putText(frame, 'Ready? Press "Q" ! :)', (100, 50), cv2.FONT_HERSHEY_SIMPLEX, 1.3, (0, 255, 0), 3, cv2.LINE_AA)
        cv2.imshow('frame', frame)

        if cv2.waitKey(25) & 0xFF == ord('q'):
            break

    # Collect images for the class
    counter = 0
    while counter < dataset_size:
        ret, frame = cap.read()
        if not ret:
            print("Error: Failed to capture frame. Stopping data collection.")
            break

        cv2.imshow('frame', frame)
        if cv2.waitKey(25) & 0xFF == ord('q'):
            print("Data collection interrupted by user.")
            break

        # Save the captured frame as an image file
        image_path = os.path.join(class_dir, f'{counter}.jpg')
        cv2.imwrite(image_path, frame)
        print(f'Image {counter} saved at {image_path}')

        counter += 1

# Release the capture and close windows
cap.release()
cv2.destroyAllWindows()
print("Data collection completed.")
