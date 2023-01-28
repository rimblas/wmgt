create or replace package uc_list_extension as  
   /** 
    * Plug-ins Pro List Extension is an Oracle APEX plug-in designed to improve user experience when adding new values to an existing List of Values (LOV). 
    * Users can quickly and easily add a new value to an existing Select List, Popup LOV, Radio Group, Checkbox, or Shuttle and automatically select the newly created value - all without leaving the page they are working on or losing their place in the application!
    * 
    * <pre>
    * Date        Author        Comment
    * ---------------------------------------------------------------------------------------
    * 08.02.2021  A. Grlica     initial creation
    * 30.04.2021  A. Grlica     IG support v 21.2
    * 
    * </pre>
    * 
    * @headcom
    */
  function render (
    p_dynamic_action in apex_plugin.t_dynamic_action,
    p_plugin         in apex_plugin.t_plugin )
    return apex_plugin.t_dynamic_action_render_result;
    
  function ajax (
    p_dynamic_action in apex_plugin.t_dynamic_action,
    p_plugin         in apex_plugin.t_plugin )
    return apex_plugin.t_dynamic_action_ajax_result;
end UC_LIST_EXTENSION;
/
create or replace package body UC_LIST_EXTENSION as   
   /** 
    * Plug-ins Pro List Extension is an Oracle APEX plug-in designed to improve user experience when adding new values to an existing List of Values (LOV). 
    * Users can quickly and easily add a new value to an existing Select List, Popup LOV, Radio Group, Checkbox, or Shuttle and automatically select the newly created value - all without leaving the page they are working on or losing their place in the application!
    * 
    * <pre>
    * Date        Author        Comment
    * ---------------------------------------------------------------------------------------
    * 08.02.2021  A. Grlica     initial creation
    * 30.04.2021  A. Grlica     IG support v 21.2
    * 
    * </pre>
    * 
    * @headcom
    */
 
c_version    constant varchar2(15 char) := '21.2.0.0';
c_log_prefix constant varchar2(30 char) := 'UC LISTEXTENSION >';
l_item     apex_application_page_items%rowtype;
l_column   apex_appl_page_ig_columns%rowtype;
l_lov      apex_application_lovs%rowtype;
procedure set_page_item(p_item_name in apex_application_page_items.item_name%type)
is
begin
    select *
        into l_item
        from apex_application_page_items
        where application_id = v('APP_ID')
        and item_name = upper(p_item_name);
exception
    when no_data_found then
        apex_debug.error('%s Item Parameter "%s" it''s not valid Page item!', c_log_prefix, upper(p_item_name));
        raise_application_error(-20001, c_log_prefix||' Item Parameter "'||upper(p_item_name)||'" it''s not valid Page item!');
end;
procedure set_grid_column(p_static_id   in apex_application_page_regions.static_id%type,
                          p_column_name in apex_appl_page_ig_columns.name%type)
is
begin
    select col.* 
      into l_column
      from apex_appl_page_igs ig
           inner join apex_application_page_regions reg  on (reg.region_id = ig.region_id)
           inner join apex_appl_page_ig_columns col on (col.region_id = ig.region_id)
     where ig.application_id = v('APP_ID')
       and ig.page_id = v('APP_PAGE_ID')
       and reg.static_id = p_static_id
       and col.name = upper(p_column_name);
exception
    when no_data_found then
        apex_debug.error('%s Interactive Grid with static id "%s" and column name "%s" do not exist, please check settings!', c_log_prefix, p_static_id, upper(p_column_name));
        raise_application_error(-20001, c_log_prefix||' Interactive Grid with static id "'||p_static_id||'" and column name "'||upper(p_column_name)||'" do not exist, please check settings!');
end;
procedure set_lov
is
begin
    if l_item.item_id is not null 
    then
        select *
            into l_lov
            from apex_application_lovs
            where application_id = v('APP_ID')
            and list_of_values_name = l_item.lov_named_lov;
    else 
        select *
            into l_lov
            from apex_application_lovs
            where application_id = v('APP_ID')
            and lov_id = l_column.lov_id;
    end if;
exception
    when no_data_found then
        apex_debug.error('%s LOV load "%s" problem!', c_log_prefix, l_item.lov_named_lov);
        raise_application_error(-20002, c_log_prefix||' LOV load "'||l_item.lov_named_lov||'" problem!');
end;
function render (
    p_dynamic_action in apex_plugin.t_dynamic_action,
    p_plugin         in apex_plugin.t_plugin )
    return apex_plugin.t_dynamic_action_render_result
is
    l_result apex_plugin.t_dynamic_action_render_result;
    l_ajax_needed boolean := false;
    
begin
    if apex_application.g_debug 
    then
        apex_debug.message('%s rendering started : version - %s', c_log_prefix, c_version);
        apex_plugin_util.debug_dynamic_action (
            p_plugin         => p_plugin,
            p_dynamic_action => p_dynamic_action );
    end if;
    if p_dynamic_action.attribute_05 = 'PI'
    then
        set_page_item(p_dynamic_action.attribute_01);
        if l_item.display_as_code not in ('NATIVE_CHECKBOX', 'NATIVE_POPUP_LOV', 'NATIVE_RADIOGROUP', 'NATIVE_SELECT_LIST', 'NATIVE_SHUTTLE')
        then
                apex_debug.error('%s Item error "%s", item must be SelectList, PopupLov, Radiogroup, Checkboxgroup or Shuttle type.', c_log_prefix, upper(p_dynamic_action.attribute_01));
                raise_application_error(-20003, c_log_prefix||' Item error "'||upper(p_dynamic_action.attribute_01)||'", item must be SelectList, PopupLov, Radiogroup, Checkboxgroup or Shuttle type.');       
        end if;
        if l_item.lov_named_lov is null and l_item.display_as_code like 'NATIVE_POPUP_LOV'
        then
                apex_debug.error('%s Item "%s" error, Popup LOV item must be be dynamic type (inside "Shared components LOV").', c_log_prefix, upper(p_dynamic_action.attribute_01));
                raise_application_error(-20004, c_log_prefix||' Item "'||upper(p_dynamic_action.attribute_01)||'" error, Popup LOV item must be be dynamic type (inside "Shared components LOV").');    
        elsif l_item.lov_named_lov is not null
        then
            set_lov;
        end if;
        if l_item.display_as_code  = 'NATIVE_POPUP_LOV'
        then
            l_ajax_needed := true;
        end if;
        
    else -- Interactive grid
        set_grid_column(p_static_id   => p_dynamic_action.attribute_06,
                        p_column_name => p_dynamic_action.attribute_07);
                        
        if l_column.item_type not in ('NATIVE_CHECKBOX', 'NATIVE_POPUP_LOV', 'NATIVE_RADIOGROUP', 'NATIVE_SELECT_LIST', 'NATIVE_SHUTTLE')
        then
                apex_debug.error('%s Column type error "%s", column must be SelectList, PopupLov, Radiogroup, Checkboxgroup or Shuttle type.', c_log_prefix, upper(p_dynamic_action.attribute_07));
                raise_application_error(-20005, c_log_prefix||' Item error "'||upper(p_dynamic_action.attribute_07)||'", item must be SelectList, PopupLov, Radiogroup, Checkboxgroup or Shuttle type.');       
        end if;       
        
        if l_column.lov_type_code not like 'SHARED' and l_column.item_type like 'NATIVE_POPUP_LOV'
        then
                apex_debug.error('%s Column "%s" error, Popup LOV item must be be dynamic type (inside "Shared components LOV").', c_log_prefix, upper(p_dynamic_action.attribute_07));
                raise_application_error(-20006, c_log_prefix||' Column "'||upper(p_dynamic_action.attribute_07)||'" error, Popup LOV item must be be dynamic type (inside "Shared components LOV").');    
        elsif l_column.lov_id is not null
        then
            set_lov;
        end if;        
        if l_column.item_type  = 'NATIVE_POPUP_LOV'
        then
            l_ajax_needed := true;
        end if;
        
    end if;
    if upper(l_lov.lov_type) = 'STATIC'
    then
        apex_debug.error('%s error Shared LOV "%s" must be dynamic type.', c_log_prefix, l_item.lov_named_lov);
        raise_application_error(-20007, c_log_prefix||' error Shared LOV "'||l_item.lov_named_lov||'" must be dynamic type.');  
    end if;
    
    l_result.javascript_function := 'uc.ListExtension.init';
    if l_ajax_needed
    then
        l_result.ajax_identifier     := apex_plugin.get_ajax_identifier;
    end if;
    l_result.attribute_01        := p_dynamic_action.attribute_01;
    l_result.attribute_02        := p_dynamic_action.attribute_02;
    l_result.attribute_03        := case when p_dynamic_action.attribute_03 = 'append' then 'true' else 'false' end;
    l_result.attribute_04        := case p_dynamic_action.attribute_04 when 'top' then 'flex-start' when 'center' then 'center' when 'bottom' then 'flex-end' when 'popup-inline' then 'popup-inline' end;
    l_result.attribute_05        := p_dynamic_action.attribute_05;
    l_result.attribute_06        := p_dynamic_action.attribute_06;
    l_result.attribute_07        := p_dynamic_action.attribute_07;
    l_result.attribute_08        := case when p_dynamic_action.attribute_05 = 'IG' then coalesce(l_column.static_id, 'C'||l_column.column_id) else null end;
  
  
  return l_result;
end;
function ajax (
    p_dynamic_action in apex_plugin.t_dynamic_action,
    p_plugin         in apex_plugin.t_plugin )
    return apex_plugin.t_dynamic_action_ajax_result
is
    l_context apex_exec.t_context; 
    l_filters apex_exec.t_filters;
    l_idx_display    pls_integer;
    l_idx_return     pls_integer;    
    l_result apex_plugin.t_dynamic_action_ajax_result;
begin
    if p_dynamic_action.attribute_05 = 'PI'
    then
        set_page_item(p_dynamic_action.attribute_01);
    else -- Interactive grid
        set_grid_column(p_static_id   => p_dynamic_action.attribute_06,
                        p_column_name => p_dynamic_action.attribute_07);
    end if;
    
    set_lov;
    apex_exec.add_filter(
        p_filters     => l_filters,
        p_filter_type => apex_exec.c_filter_eq,
        p_column_name => l_lov.return_column_name,
        p_value       => apex_application.g_x01 );
    l_context := apex_exec.open_query_context(
        p_location          => l_lov.location_code,
        
        p_table_owner            => l_lov.table_owner,
        p_table_name             => l_lov.table_name,
        p_where_clause           => l_lov.where_clause,   
        p_sql_query              => case when l_lov.source_type_code = 'SQL' then l_lov.list_of_values_query end,
        p_plsql_function_body    => case when l_lov.source_type_code = 'FUNC_BODY_RETURNING_SQL' then l_lov.list_of_values_query end,
        p_optimizer_hint         => l_lov.optimizer_hint,
        p_filters               => l_filters
    );
    
    
    l_idx_display    := apex_exec.get_column_position( l_context, l_lov.display_column_name); 
    l_idx_return     := apex_exec.get_column_position( l_context, l_lov.return_column_name); 
    while apex_exec.next_row( l_context ) loop
        apex_json.open_object;
        apex_json.write('id',     apex_exec.get_varchar2( l_context, l_idx_return ));        
        apex_json.write('value',  apex_exec.get_varchar2( l_context, l_idx_display ));
        apex_json.close_object;
    end loop;
    --        
    apex_exec.close( l_context );    
    return l_result;
exception
    when others then
        apex_exec.close( l_context );
        raise;      
end;
 
end UC_LIST_EXTENSION;
/