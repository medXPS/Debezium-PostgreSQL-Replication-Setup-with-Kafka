CREATE TABLE public.test (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50)
);

INSERT INTO test (first_name, last_name) VALUES ('John', 'Doe');