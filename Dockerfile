# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set the working directory in the container
WORKDIR /home/ubuntu/app

# Copy the current directory contents into the container at /app
COPY . /home/ubuntu/app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable
ENV NAME World

# Run application.py using python3 when the container launches
CMD ["python3", "app.py"]
