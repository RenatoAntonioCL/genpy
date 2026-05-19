FROM kalilinux/kali-rolling
WORKDIR /workspace

# Evitar alertas interactivas durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar el gestor de paquetes e instalar herramientas core del Red Team
RUN apt-get update && apt-get install -y --no-install-recommends \
    nmap \
    sqlmap \
    hydra \
    curl \
    git \
    python3 \
    python3-pip \
    python3-scapy \
    iproute2 \
    iputils-ping \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . .
CMD ["/bin/bash"]