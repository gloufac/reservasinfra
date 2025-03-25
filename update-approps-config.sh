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
