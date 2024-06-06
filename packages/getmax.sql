create or replace function getmax(p_table_name in varchar2, p_column_name in varchar2) return number
is
  l_n number;
begin
  execute immediate 'select max('||p_column_name||') from ' || p_table_name into l_n;
  return l_n;
end getmax;
/
