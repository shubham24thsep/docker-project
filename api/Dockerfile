# Use a stable Node image
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Install nodemon globally
RUN npm install -g nodemon

# Copy package.json and package-lock.json first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the app
COPY . .

# Expose port (customize if needed)
EXPOSE 5000

# Start the app using nodemon
CMD ["nodemon", "index.js"]
