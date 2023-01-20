# container image
FROM ubuntu:22.04

# set working directory
WORKDIR /app

# copy everything
COPY . .

# set timezone
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && \
    echo $CONTAINER_TIMEZONE > /etc/timezone

# update package information
RUN apt-get update

# install dependencies
RUN apt-get install -y cc65 make
