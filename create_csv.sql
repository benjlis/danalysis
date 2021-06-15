\copy (select column_name, data_type, not_null_count, distinct_count, column_population, min_value, max_value, lov from danalysis_columns order by ordinal_position) TO 'danalysis.csv' NULL 'N/A'
