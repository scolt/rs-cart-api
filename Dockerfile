# The first stage only for build needs, for optimizing size of docker image
FROM node:12-alpine as BUILD-STAGE

# Create temporary directory for build
WORKDIR /temporary-build
# Install additional dependencies which is not a part of alpine image
RUN apk update && apk add curl bash && rm -rf /var/cache/apk/*
RUN curl -sfL https://install.goreleaser.com/github.com/tj/node-prune.sh | bash -s -- -b /temporary-build

# Install tmp dependencies
# For the first step copy only package.json(s) if install will be failed the other commands will be skipped
COPY ["package.json", "package-lock.json*", "./"]
RUN npm i
# Prepare and build our application
COPY . ./
RUN npm run build
# Update our dependencies to production mode
RUN npm prune --production
# Remove some unnecesssary files from node_modules
RUN /temporary-build/node-prune

# The second stage for packing the build to the container
FROM node:12-alpine
WORKDIR /application

COPY --from=BUILD-STAGE /temporary-build/dist ./dist
COPY --from=BUILD-STAGE /temporary-build/node_modules ./node_modules

# Bundle app source
EXPOSE 8080
CMD [ "node", "./main" ]
