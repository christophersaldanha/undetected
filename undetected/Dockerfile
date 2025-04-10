FROM ubuntu:20.04

RUN apt update && apt install -y iproute2 iputils-ping net-tools netcat curl

# Copy bgmi binary to the container and set permissions
COPY bgmi /workspaces/undetected/undetected/bgmi
RUN ls -l /workspaces/undetected/undetected/bgmi
RUN chmod +x /workspaces/undetected/undetected/bgmi

# Define the logs directory as a volume so that it can be mapped to the host system
VOLUME ["/logs"]

CMD ["bash"]
