import cv2
cap = cv2.VideoCapture("/Users/jaspersands/Downloads/IMG_0226.mp4")
if not cap.isOpened():
    print("Video opened successfully.")
else:
    print("Failed to open video.")