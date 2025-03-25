#!/bin/bash

echo "***************Inicio actualizacion de parametros en application-prod.properties***************"
# Ruta del archivo de configuración en la EC2
CONFIG_FILE="/opt/reservasgl/config/application-prod.properties"

echo "1. Obtener AWS Parameter Store"
# Obtener valores desde AWS Parameter Store
DB_URL=$(aws ssm get-parameter --name "/ReservasGL/DB_Url" --with-decryption --query "Parameter.Value" --output text)
DB_USERNAME=$(aws ssm get-parameter --name "/ReservasGL/DB_Username" --with-decryption --query "Parameter.Value" --output text)
DB_PASSWORD=$(aws ssm get-parameter --name "/ReservasGL/DB_Password" --with-decryption --query "Parameter.Value" --output text)
LOC_JWTSecretKey=$(aws ssm get-parameter --name "/ReservasGL/JWTSecretKey" --with-decryption --query "Parameter.Value" --output text)
LOC_RS3_AccessKeyId=$(aws ssm get-parameter --name "/ReservasGL/RS3_AccessKeyId" --with-decryption --query "Parameter.Value" --output text)
LOC_RS3_SecretKey=$(aws ssm get-parameter --name "/ReservasGL/RS3_SecretKey" --with-decryption --query "Parameter.Value" --output text)
LOC_RSES_Username=$(aws ssm get-parameter --name "/ReservasGL/RSES_Username" --with-decryption --query "Parameter.Value" --output text)
LOC_RSES_Password=$(aws ssm get-parameter --name "/ReservasGL/RSES_Password" --with-decryption --query "Parameter.Value" --output text)

echo "2. Actualizar valores en application-prod.properties"
# Reemplazar valores en application-prod.properties
sed -i "s|^spring.datasource.url=.*|spring.datasource.url=${DB_URL}|" "$CONFIG_FILE"
sed -i "s|^spring.datasource.username=.*|spring.datasource.username=${DB_USERNAME}|" "$CONFIG_FILE"
sed -i "s|^spring.datasource.password=.*|spring.datasource.password=${DB_PASSWORD}|" "$CONFIG_FILE"
sed -i "s|^sec.secretkey=.*|sec.secretkey=${LOC_JWTSecretKey}|" "$CONFIG_FILE"
sed -i "s|^bucket.accessKeyId=.*|bucket.accessKeyId=${LOC_RS3_AccessKeyId}|" "$CONFIG_FILE"
sed -i "s|^bucket.acccessSecKey=.*|bucket.acccessSecKey=${LOC_RS3_SecretKey}|" "$CONFIG_FILE"
sed -i "s|^email.username=.*|email.username=${LOC_RSES_Username}|" "$CONFIG_FILE"
sed -i "s|^email.password=.*|email.password=${LOC_RSES_Password}|" "$CONFIG_FILE"

# Asignar permisos adecuados
echo "3. Asignar permisos adecuados al archivo"
sudo chmod 600 $CONFIG_FILE
sudo chown $(whoami) $CONFIG_FILE

echo "4. Configuración actualizada en $CONFIG_FILE"
echo "***************Fin actualizacion de parametros en application-prod.properties***************"
echo "*******************************************************************************************"


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

$LOC_VITE_TOKEN=$(echo "$RESPONSE" | jq -r '.data.access_token')

# Verificar si el TOKEN se obtuvo correctamente
if [[ -z "$LOC_VITE_TOKEN" || "$LOC_VITE_TOKEN" == "null" ]]; then
  echo "Error: No se pudo obtener el access_token"
  exit 1
fi

echo "2. Actualizar valores en archivo env"
sed -i "s/^VITE_GUEST_TOKEN=.*/VITE_GUEST_TOKEN=$LOC_VITE_TOKEN/" "$CONFIG_FILE_ENV"
sed -i "s/^VITE_SOURCE_IMAGES=.*/VITE_SOURCE_IMAGES=$LOC_VITE_SOURCE_IMAGES/" "$CONFIG_FILE_ENV"

echo "3. Datos actualizados en $CONFIG_FILE_ENV"
