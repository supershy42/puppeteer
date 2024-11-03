-- srcs/database/init.sql

-- my_database가 없으면 생성
SELECT 'CREATE DATABASE my_database'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'my_database') \gexec

-- my_database로 전환
\c my_database;

-- 사용자 테이블 생성
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 예시 데이터 삽입 (옵션)
INSERT INTO users (username, password, email)
VALUES ('admin', 'hashed_password_here', 'admin@example.com');