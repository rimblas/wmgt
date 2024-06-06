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

-- putting object from directory to object storage
-- Go to the bucket you want to write (in our case wmgt-dmp) get a "Pre-Authenticated Requests" and place it in l_obj_url
declare
 -- this is the url to the bucket
 l_obj_url    varchar2(200) := 'https://objectstorage.us-ashburn-1.oraclecloud.com/CREDENTIALS_HERE/wmgt-dmp/o/';
 -- https://idw1nygcxpvm.objectstorage.us-ashburn-1.oci.customer-oci.com/p/hxa_5RHNGeGzmmh1GZHq99fkTiS3kbhmZXZ-a4PSRmgXGJqtHoBg5EhTAQT9wH_K/n/idw1nygcxpvm/b/wmgt-dmp/o/
 l_cred_name  varchar2(100) := 'DBIMPEXP_CRED';

begin
 for r in (
  select object_name, bytes
    from dbms_cloud.list_files('DATA_PUMP_DIR')
   where object_name like 'wmgt%'
 )
 loop
  dbms_cloud.put_object(credential_name => l_cred_name,
                        object_uri      => l_obj_url||r.object_name,
                        directory_name  => 'DATA_PUMP_DIR',
                        file_name       => r.object_name);
 end loop;     
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
