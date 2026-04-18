create or replace view wmg_badge_types_vl
as
select t.id
     , t.code
     , t.name
     , jd.lang
     , jd.tl description
     , t.display_seq
     , t.icon_class
     , t.system_calculated_ind
     , t.selectable_ind
     , t.active_ind
     , t.description_jtl
     , t.created_by
     , t.created_on
     , t.updated_by
     , t.updated_on
  from wmg_badge_types t
     , json_table(t.description_jtl, '$[*]'
        columns (
             lang varchar2(10)      path '$.l'
           , tl   varchar2(60 char) path '$.tl'
       )) jd
 where jd.lang = (select nvl(apex_util.get_session_lang,'en') from dual)
/