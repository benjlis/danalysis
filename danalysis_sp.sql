create or replace function danalysis(
    table_schema_arg  information_schema.sql_identifier,
    table_name_arg    information_schema.sql_identifier)
returns void as $$
begin
   delete from danalysis where table_schema = table_schema_arg and
                               table_name = table_name_arg;
   insert into danalysis (table_schema, table_name, danalysis_time, row_count)
   select table_schema, table_name, current_timestamp, 0
      from information_schema.tables
      where table_schema = table_schema_arg and
            table_name = table_name_arg;
end $$
language plpgsql;
