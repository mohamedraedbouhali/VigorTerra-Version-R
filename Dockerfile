# Stage 1: Build the React application
FROM node:18-alpine AS build

# Set the working directory
WORKDIR /app

# Build-time API base URL consumed by Vite (import.meta.env.VITE_API_URL)
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL}

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application source code
COPY . .

# Build the Vite application for production
RUN npm run build

# Stage 2: Serve the application with Nginx
FROM nginx:alpine

# Copy the built assets from the previous stage to Nginx's web root
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80 to access the Nginx server
EXPOSE 80

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
