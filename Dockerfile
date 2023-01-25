FROM ubuntu:22.04

# set working directory
WORKDIR /app

# copy packages.txt into image
COPY packages.txt .

# set timezone
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && \
    echo $CONTAINER_TIMEZONE > /etc/timezone

# update package information and install required packages
RUN apt-get update && \
    xargs -a packages.txt apt-get install -y
