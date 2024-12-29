FROM postgres:latest

# PostgreSQL 설정 복사
COPY postgres.conf /etc/postgresql/postgresql.conf

# PostgreSQL 초기화 스크립트 복사
# COPY init.sql /docker-entrypoint-initdb.d/

# 데이터 디렉토리 및 로그 파일 설정
# RUN mkdir -p /var/lib/postgresql/data && \
#     chown -R postgres:postgres /var/lib/postgresql/data && \
#     chmod 755 /var/lib/postgresql/data

# 설정 적용
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]