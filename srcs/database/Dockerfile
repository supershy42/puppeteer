# srcs/database/Dockerfile
FROM postgres:latest

# 환경 변수 설정 (비밀번호는 개발 환경에서 임시로 사용)
ENV POSTGRES_DB=mydatabase
ENV POSTGRES_USER=myuser
ENV POSTGRES_PASSWORD=mypassword

# 초기화 스크립트 복사
COPY init.sql /docker-entrypoint-initdb.d/

# PostgreSQL 설정 파일 복사 (필요한 경우)
# COPY postgres.conf /etc/postgresql/postgresql.conf