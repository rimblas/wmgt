create or replace view wmg_course_previews_v
as
select p.id
     , p.course_id
     , p.hole
     , p.same_as_id
     , nvl(s.image_preview, p.image_preview) image_preview
     , nvl(s.mimetype, p.mimetype) mimetype
     , nvl(s.filename, p.filename) filename
     , nvl(s.image_last_update, p.image_last_update) image_last_update
     , p.created_on
     , p.created_by
     , p.updated_on
     , p.updated_by
 from wmg_course_previews p
    , wmg_course_previews s
where p.same_as_id = s.id (+) 
/
