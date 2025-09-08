# Subqueries opgave (PostgreSQL)

## Kør Postgres i Docker
```bash
docker rm -f postgres-db 2>nul | out-null
docker run --name postgres-db -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -p 5432:5432 -d postgres:16
