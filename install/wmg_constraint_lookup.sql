create table wmg_constraint_lookup (
   constraint_name varchar2(128)
 , message varchar2(4000) not null enable,
   primary key (constraint_name) using index  enable
)
/