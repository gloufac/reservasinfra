#!/bin/bash

# Levantar solo el reservasbe
## docker-compose up -d reservasbe
docker-compose -f docker-compose.yml up --build -d reservasbe

# Esperar a que el reservasbe esté saludable
echo "Esperando a que el reservasbe esté listo..."
until docker inspect --format='{{json .State.Health.Status}}' reservasbe | grep -q "healthy"; do
  sleep 5
done

# Ejecutar updateenv.sh en EC2
echo "Ejecutando updateenv.sh en EC2..."
chmod +x updateenv.sh
./updateenv.sh

# Ahora levantar el reservasfe
## docker-compose up -d reservasfe
docker-compose -f docker-compose.yml up --build -d reservasfe