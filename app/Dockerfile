# This Dockerfile is used to build the Node.js application image

FROM node:18-alpine

# Create application directory
WORKDIR /usr/src/app

# Copy application source code
COPY . . 

# Expose the port the application runs on
EXPOSE 8080

# Define the command to run the application inside the container
CMD ["node", "server.js"]