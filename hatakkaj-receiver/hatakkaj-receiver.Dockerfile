ROM alpine:latest

# Install rsync
RUN apk add --no-cache rsync

# Set entrypoint or default command
# This will be over ridden in yaml anyway
ENTRYPOINT ["rsync"]
CMD ["--help"]
