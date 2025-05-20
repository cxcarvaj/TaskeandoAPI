export PASSWORD=$(openssl rand -base64 32)
echo "PostgreSQL password: $PASSWORD"
docker run -d \
  --name taskeandoDB \
  -e POSTGRES_DB=taskeandoDB \
  -e POSTGRES_USER=taskUser \
  -e POSTGRES_PASSWORD=$PASSWORD \
  -p 5432:5432 \
  -v taskeando_data:/var/lib/postgresql/data \
  postgres:latest
echo "PostgreSQL password saved to ./pg_password.txt"
echo "$PASSWORD" > ./pg_password.txt
