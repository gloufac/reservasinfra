echo "***************Inicio actualizacion de parametros en archivo env***************"
# Ruta del archivo de configuración en la EC2
CONFIG_FILE_ENV="/opt/reservasgl/config/.env"

echo "1. Obtener parametros de AWS Parameter Store"
LOC_VITE_SOURCE_IMAGES=$(aws ssm get-parameter --name "/ReservasGL/FE/vite_source_images" --with-decryption --query "Parameter.Value" --output text)
LOC_GUEST_USERNAME=$(aws ssm get-parameter --name "/ReservasGL/FE/GuestUsername" --with-decryption --query "Parameter.Value" --output text)
LOC_GUEST_PASSWORD=$(aws ssm get-parameter --name "/ReservasGL/FE/GuestPassword" --with-decryption --query "Parameter.Value" --output text)

# Validar que los parámetros no estén vacíos
if [[ -z "$LOC_GUEST_USERNAME" || -z "$LOC_GUEST_PASSWORD" ]]; then
  echo "Error: en la lectura de parametros para usuario y password"
  exit 1
fi

echo "2. Hacer peticion para obtener el token de invitado"
JSON_DATA='{"username": "'"$LOC_GUEST_USERNAME"'", "password": "'"$LOC_GUEST_PASSWORD"'"}'
RESPONSE=$(curl --silent --show-error --write-out "HTTPSTATUS:%{http_code}" --location 'http://localhost:8080/api/auth/login' \
  --header 'Content-Type: application/json' \
  --data-raw "$JSON_DATA")

# Extraer el código de estado y la respuesta
###BODY=$(echo "$LOC_VITE_TOKEN" | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
##echo "Response Body: $BODY"
STATUS=$(echo "$RESPONSE" | grep -oE '[0-9]{3}$')
echo "HTTP Status: $STATUS"

# Validar si la solicitud fue exitosa
if [ "$STATUS" -ne 200 ]; then
  echo "Error: La solicitud falló con código $STATUS"
  exit 1
fi

echo "3. Extraer el token de la respuesta"
$LOC_VITE_TOKEN=$(echo "$RESPONSE" | jq -r '.data.access_token')

# Verificar si el TOKEN se obtuvo correctamente
if [[ -z "$LOC_VITE_TOKEN" || "$LOC_VITE_TOKEN" == "null" ]]; then
  echo "Error: No se pudo obtener el access_token"
  exit 1
fi

echo "2. Actualizar valores en archivo env"
sed -i "s|^VITE_GUEST_TOKEN=.*|VITE_GUEST_TOKEN=${LOC_VITE_TOKEN}|" "$CONFIG_FILE_ENV"
sed -i "s|^VITE_SOURCE_IMAGES=.*|VITE_SOURCE_IMAGES=${LOC_VITE_SOURCE_IMAGES}|" "$CONFIG_FILE_ENV"

echo "3. Datos actualizados en $CONFIG_FILE_ENV"
