# Minimal base image for Altaïr labs
FROM alpine:3.20

# Always update security packages
RUN apk update && apk upgrade

# Install minimal tools useful for teaching/testing
RUN apk add --no-cache bash coreutils curl nano

# Optional: create a non-root user
RUN adduser -D student
USER student
WORKDIR /home/student

CMD ["bash"]
