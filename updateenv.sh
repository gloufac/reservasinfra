echo "***************Inicio actualizacion de parametros en archivo env***************"
# Ruta del archivo de configuración en la EC2
CONFIG_FILE_ENV="/opt/reservasgl/config/.env"
ls /opt/reservasgl/config/

echo "1. Obtener parametros de AWS Parameter Store"
LOC_VITE_SOURCE_IMAGES=$(aws ssm get-parameter --name "/ReservasGL/FE/vite_source_images" --with-decryption --query "Parameter.Value" --output text)
LOC_GUEST_USERNAME=$(aws ssm get-parameter --name "/ReservasGL/FE/GuestUsername" --with-decryption --query "Parameter.Value" --output text)
LOC_GUEST_PASSWORD=$(aws ssm get-parameter --name "/ReservasGL/FE/GuestPassword" --with-decryption --query "Parameter.Value" --output text)
LOC_VITE_URL='http://reservasbe:8080'

# Validar que los parámetros no estén vacíos
if [[ -z "$LOC_GUEST_USERNAME" || -z "$LOC_GUEST_PASSWORD" ]]; then
  echo "Error: en la lectura de parametros para usuario y password"
  exit 1
fi

echo "2. Hacer peticion para obtener el token de invitado"
JSON_DATA="{\"username\": \"$LOC_GUEST_USERNAME\", \"password\": \"$LOC_GUEST_PASSWORD\"}"
RESPONSE=$(curl --silent --write-out "\nHTTPSTATUS:%{http_code}" --location 'http://localhost:8080/api/auth/login' \
  --header 'Content-Type: application/json' \
  --data-raw "$JSON_DATA")

# Separar el cuerpo de la respuesta y el código HTTP
HTTP_STATUS=$(echo "$RESPONSE" | grep -oP 'HTTPSTATUS:\K\d+')
JSON_RESPONSE=$(echo "$RESPONSE" | sed -E 's/HTTPSTATUS:[0-9]+//')

# Mostrar la respuesta completa (opcional, útil para depuración)
echo "Respuesta del servidor: $JSON_RESPONSE"
echo "Código HTTP: $HTTP_STATUS"
# Si necesitas validar el código de estado HTTP
if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "Autenticación exitosa"
else
  echo "Error en autenticación (HTTP $HTTP_STATUS)"
  exit 1
fi

echo "3. Extraer el token de la respuesta"
# Verificar si la respuesta es JSON válido
if echo "$JSON_RESPONSE" | jq empty 2>/dev/null; then
  # Extraer el token de acceso
  ACCESS_TOKEN=$(echo "$JSON_RESPONSE" | jq -r '.data.access_token')
  # echo "Access Token: $ACCESS_TOKEN"

  echo "4. Actualizar valores en archivo env"
  sed -i "s|^VITE_API_URL=.*|VITE_API_URL=${LOC_VITE_URL}|" "$CONFIG_FILE_ENV"
  sed -i "s|^VITE_GUEST_TOKEN=.*|VITE_GUEST_TOKEN=${ACCESS_TOKEN}|" "$CONFIG_FILE_ENV"
  sed -i "s|^VITE_SOURCE_IMAGES=.*|VITE_SOURCE_IMAGES=${LOC_VITE_SOURCE_IMAGES}|" "$CONFIG_FILE_ENV"
  echo "5. Datos actualizados en $CONFIG_FILE_ENV"
else
  echo "Error: La respuesta no es un JSON válido"
  exit 1
fi
