create or replace function danalysis_dysel(qexpr text)
returns text as $$
declare
    qresult text;
begin
    execute 'select ' || qexpr into strict qresult;
    return qresult;
end $$
language plpgsql;

create or replace function danalysis(
    table_name_arg    information_schema.sql_identifier,
    table_schema_arg  information_schema.sql_identifier = current_schema()
    )
returns record as $$
declare
    ret record;
    rcnt int;
begin
    delete from danalysis
       where table_schema = table_schema_arg and
             table_name = table_name_arg;
   -- WHy not use upsert instead of delete/insert? Delete/insert enables a
   -- call to danalysis to clear stats for dropped tables.
   -- Add table level details.
   insert into danalysis (table_schema, table_name, danalysis_time)
   select table_schema, table_name, current_timestamp
      from information_schema.tables
      where table_schema = table_schema_arg and
            table_name = table_name_arg;
   get diagnostics rcnt = ROw_COUNT;
   if rcnt = 1 then   -- table exists
      update danalysis
         set row_count = cast(danalysis_dysel('count(*) from '||
                            table_name_arg) as integer),
             column_count = (select count(*)
                               from information_schema.columns
                               where table_schema = table_schema_arg and
                                     table_name = table_name_arg)
         where table_schema = table_schema_arg and
               table_name = table_name_arg;
      -- column level processing
      insert into danalysis_columns (table_schema, table_name,
         column_name, ordinal_position)
      select table_schema, table_name, column_name, ordinal_position
         from information_schema.columns
         where table_schema = table_schema_arg and
               table_name = table_name_arg;
      update danalysis_columns
         set count_not_null = cast(danalysis_dysel('count(' || column_name ||
                                 ') from '|| table_name) as integer),
             count_distinct = cast(danalysis_dysel('count(distinct ' ||
                                 column_name || ') from '|| table_name)
                                 as integer)
        where table_schema = table_schema_arg and
              table_name = table_name_arg;
      --
      select table_schema, table_name, danalysis_time, row_count, column_count
         into ret
         from danalysis
         where table_schema = table_schema_arg and
               table_name = table_name_arg;
    else  --table does not exist
        select 'Table not found' into ret;
    end if;
    return ret;
end $$
language plpgsql;
