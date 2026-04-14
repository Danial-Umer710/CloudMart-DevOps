FROM nginx:alpine

# 1. Declare the argument from GitHub Actions
ARG REACT_APP_API_URL

# 2. Remove default assets
RUN rm -rf /usr/share/nginx/html/*

# 3. Copy your index.html
COPY index.html /usr/share/nginx/html/index.html

# 4. THE FIX: Search for the old IP and replace it with the new one
# We use | as a delimiter because the URL contains slashes
RUN sed -i "s|http://13.49.46.219|${REACT_APP_API_URL}|g" /usr/share/nginx/html/index.html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
