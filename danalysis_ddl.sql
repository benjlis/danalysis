create table if not exists danalysis (
    table_schema    information_schema.sql_identifier not null,
    table_name      information_schema.sql_identifier not null,
    danalysis_time  timestamptz                       not null,
    row_count       integer,
    column_count    integer,
    primary key (table_schema, table_name)
    );

create table if not exists danalysis_columns (
    table_schema     information_schema.sql_identifier,
    table_name       information_schema.sql_identifier,
    column_name      information_schema.sql_identifier,
    ordinal_position information_schema.cardinal_number,
    count_not_null   integer,
    count_distinct   integer,
    primary key (table_schema, table_name,  column_name),
    foreign key (table_schema, table_name) references danalysis
        on delete cascade
    );
