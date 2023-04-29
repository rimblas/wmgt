set serveroutput on size unlimited;
begin
apex_application_install.set_workspace('WMGT');
  apex_application_install.set_application_id(200);
  apex_application_install.set_schema('WKSP_WMGT');
  -- apex_application_install.generate_offset;
  -- we want the ID to match across workspaces
  apex_application_install.set_offset(0);
end;
/