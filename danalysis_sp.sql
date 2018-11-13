create or replace function danalysis(
    table_name_arg    information_schema.sql_identifier,
    table_schema_arg  information_schema.sql_identifier = current_schema()
    )
returns record as $$
declare
    ret record;
begin
   delete from danalysis where table_schema = table_schema_arg and
                               table_name = table_name_arg;
   insert into danalysis (table_schema, table_name, danalysis_time, row_count)
   select table_schema, table_name, current_timestamp, 0
      from information_schema.tables
      where table_schema = table_schema_arg and
            table_name = table_name_arg;
    select table_schema, table_name, danalysis_time, row_count
      into ret
      from danalysis
      where table_schema = table_schema_arg and
            table_name = table_name_arg;
    return ret;
end $$
language plpgsql;
