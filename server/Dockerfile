# Use the official lightweight Node.js Alpine image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package configuration files first to leverage Docker layer caching
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy the rest of the application files
COPY . .

# Expose the port the server listens on
EXPOSE 3000

# Set environment to production
ENV NODE_ENV=production

# Start the application
CMD [ "node", "server.js" ]
