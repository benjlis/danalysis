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
    from_clause text;
    array_select text;
    from_group text;
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
                            table_schema_arg || '.' ||
                            table_name_arg) as integer),
             column_count = (select count(*)
                               from information_schema.columns
                               where table_schema = table_schema_arg and
                                     table_name = table_name_arg)
         where table_schema = table_schema_arg and
               table_name = table_name_arg;
      -- column level processing
      insert into danalysis_columns (table_schema, table_name,
             column_name, data_type, ordinal_position)
      select table_schema, table_name, column_name, data_type,
             ordinal_position
         from information_schema.columns
         where table_schema = table_schema_arg and
               table_name = table_name_arg;
      -- column counts
      from_clause = ' from ' || table_schema_arg || '.' ||table_name_arg;
      update danalysis_columns
         set not_null_count = cast(danalysis_dysel('count(' || column_name ||
                                 ') ' || from_clause) as integer),
             distinct_count = cast(danalysis_dysel('count(distinct ' ||
                                 column_name || ') ' || from_clause) as integer),
             min_value = cast(danalysis_dysel('min(' || column_name ||
                                     ') ' || from_clause) as text),
             max_value = cast(danalysis_dysel('max(' || column_name ||
                                     ') ' || from_clause) as text)
        where table_schema = table_schema_arg and
              table_name = table_name_arg;
      -- column_population
      update danalysis_columns c
         set column_population = (
             select case when c.not_null_count = 0 then 'ALL NULLS'
                         when c.distinct_count = row_count then 'CANDIDATE KEY'
                         when c.not_null_count = row_count then 'NOT NULL'
                         when c.not_null_count::float/row_count::float < .1
                            then 'SPARSE'
                         when c.not_null_count::float/row_count::float > .98
                            then 'APPROX NOT NULL'
                         else 'NULLABLE'
                    end
                from danalysis
                where table_schema = c.table_schema and
                      table_name = c.table_name)
         where table_schema = table_schema_arg and
               table_name = table_name_arg;
      -- get list of lov_values
      array_select = 'array_to_string(array(' ||
                     'select (code || '':'' || cnt) from (select ';
      from_group = from_clause ||
                   ' group by code order by cnt desc) s), '', '')';
      update danalysis_columns
         set lov = danalysis_dysel(array_select || column_name || ' code, ' ||
                      'count(' || column_name || ') cnt ' || from_group)
         where distinct_count <= 100 and
               table_schema = table_schema_arg and
               table_name = table_name_arg;
      update danalysis_columns
         set lov = 'TOO MANY DISTINCT VALUES TO LIST!'
         where distinct_count > 100 and
               table_schema = table_schema_arg and
               table_name = table_name_arg;
      -- return values
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
