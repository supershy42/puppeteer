FROM postgres:latest

# PostgreSQL 설정 복사
COPY postgres.conf /etc/postgresql/postgresql.conf

# PostgreSQL 초기화 스크립트 복사
# COPY init.sql /docker-entrypoint-initdb.d/

# 설정 적용
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]