-- List files in Data Pump Directory
select * 
  from dbms_cloud.list_files('DATA_PUMP_DIR');

-- Star Data Pump Backup Job
declare
 l_dp_handle       number;
 l_job_name        varchar2(100) := 'WMGT_WEEKLY';
 l_file_name       varchar2(100) := 'wmgt_' || to_char(sysdate, 'YYYYMMDD') || '.dmp';
 l_log_file_name   varchar2(100) := 'wmgt_' || to_char(sysdate, 'YYYYMMDD') || '.log';
 l_schema_name     varchar2(30)  := 'WKSP_WMGT';
begin
 -- Open a schema export job.
 l_dp_handle := dbms_datapump.open(operation   => 'EXPORT',
                                   job_mode    => 'SCHEMA',
                                   remote_link => null,
                                   job_name    => l_job_name,
                                   version     => '19.0');

 -- Specify the dump file name and directory object name.
 dbms_datapump.add_file(handle    => l_dp_handle,
                        filename  => l_file_name,
                        directory => 'DATA_PUMP_DIR');

 -- Specify the log file name and directory object name.
 dbms_datapump.add_file(handle    => l_dp_handle,
                        filename  => l_log_file_name,
                        directory => 'DATA_PUMP_DIR',
                        filetype  => DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);

 -- Specify the schema to be exported.
 dbms_datapump.metadata_filter(handle => l_dp_handle,
                               name   => 'SCHEMA_EXPR',
                               value  => 'IN ('''||l_schema_name||''')');
    
 dbms_datapump.start_job(l_dp_handle);

 dbms_datapump.detach(l_dp_handle);
end;
/

-- delete files from direcotry
declare
 l_file_name       varchar2(100) := 'wmgt_' || to_char(sysdate, 'YYYYMMDD') || '.dmp';
 l_log_file_name   varchar2(100) := 'wmgt_' || to_char(sysdate, 'YYYYMMDD') || '.log';
begin
 return; -- safety line
 dbms_cloud.delete_file(directory_name => 'DATA_PUMP_DIR',
                        file_name      => l_file_name );
 dbms_cloud.delete_file(directory_name => 'DATA_PUMP_DIR',
                        file_name      => l_log_file_name );
end;
/ 
