create table if not exists danalysis (
    table_schema    information_schema.sql_identifier not null,
    table_name      information_schema.sql_identifier not null,
    danalysis_time  timestamptz                       not null,
    row_count       integer,
    column_count    integer,
    primary key (table_schema, table_name)
    );

create table danalysis_column_population (
    code        text primary key,
    description text not null
    );
insert into danalysis_column_population (code,  description)
values ('ALL NULLS', 'COLUMN IS COMPLETELY UNPOPULATED'),
       ('SPARSE', 'LESS THAN 10% OF ROWS HAVE A VALUE IN then COLUMN'),
       ('NULLABLE', '10 TO 98% OF ROWS HAVE A VALUE IN THE COLUMN'),
       ('APPROX NOT NULL', 'OVER 98% OF ROWS HAVE A VALUE BUT NOT 100%'),
       ('NOT NULL', 'ALL ROWS HAVE A VALUE FOR THE COLUMN'),
       ('CANDIDATE KEY', 'COLUMN VALUE UNIQUELY IDENTIFIES ROW IN TABLE');

create table if not exists danalysis_columns (
    table_schema     information_schema.sql_identifier,
    table_name       information_schema.sql_identifier,
    column_name      information_schema.sql_identifier,
    data_type        information_schema.character_data,
    ordinal_position information_schema.cardinal_number,
    not_null_count   integer,
    distinct_count   integer,
    min_value        text,
    max_value        text,
    column_population text,
    lov              text,
    primary key (table_schema, table_name,  column_name),
    foreign key (table_schema, table_name) references danalysis
        on delete cascade,
    foreign key (column_population) references danalysis_column_population
    );
