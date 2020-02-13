# syntax=docker/dockerfile:experimental

# Build stage: Install yarn dependencies
# ===
FROM node:12-slim AS yarn-dependencies
WORKDIR /srv
ADD package.json .
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn yarn install


# Build stage: Build JavaScript
# ===
FROM yarn-dependencies AS build
ADD . .
RUN yarn run build


# Build the production image
# ===
FROM ubuntu:focal

# Set up environment
ENV LANG C.UTF-8
WORKDIR /srv

# Install nginx
RUN apt-get update && apt-get install --no-install-recommends --yes nginx

# Import code, build assets and mirror list
RUN rm -rf package.json yarn.lock .babelrc webpack.config.js requiremets.txt
COPY --from=build srv/build build

ARG BUILD_ID
ADD nginx.conf /etc/nginx/sites-enabled/default
ADD redirects.map /etc/nginx/redirects.map
RUN sed -i "s/~BUILD_ID~/${BUILD_ID}/" /etc/nginx/sites-enabled/default

STOPSIGNAL SIGTERM

# Setup commands to run server
CMD ["nginx", "-g", "daemon off;"]


