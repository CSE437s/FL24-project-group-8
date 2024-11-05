# Use the official Python 3.9 image
FROM python:3.9

# Set the working directory in the container
WORKDIR /app

# Install system dependencies for OpenCV
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install specific versions of Python dependencies
RUN pip install --no-cache-dir \
    numpy \
    Django==4.2.16 \
    dj-rest-auth==6.0.0 \
    django-allauth==65.0.1 \
    django-cors-headers==4.4.0 \
    django-rest-auth==0.9.5 \
    djangorestframework==3.15.2 \
    scikit-learn==1.5.2 \
    opencv-python==4.7.0.72 \
    mediapipe==0.10.15 \
    PyJWT==2.7.0 \
    requests==2.28.1 \
    tensorflow==2.12.0

# Copy the entire project into the container
COPY . /app/

# Set environment variables for Django
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=aslapp.settings

# Run Django server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
