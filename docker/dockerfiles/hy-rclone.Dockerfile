# syntax=docker/dockerfile:1.4
FROM alpine:latest

# Install rsync
RUN apk add --no-cache rsync rclone

WORKDIR /conf

# Set entrypoint or default command
# This will be over ridden in yaml anyway
ENTRYPOINT ["rsync"]
CMD ["--help"]
