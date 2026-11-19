-- 00037: the numbers behind the admin analytics screen.
--
-- admin_placement_report() answers in one call: how many students have an internship ("placed" =
-- an application with status 'active', i.e. an accepted offer), how applications are spread over
-- statuses, programmes, companies and postings, and which students still have no placement.
-- Only an approved administrator may call it.

create or replace function public.admin_placement_report()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v jsonb;
begin
  if (select current_user_role()) is distinct from 'admin' then
    raise exception 'Only an administrator can open the analytics.';
  end if;

  with placed as (
    select distinct student_id from applications where status = 'active'
  ), applied as (
    select student_id, count(*) as n from applications group by student_id
  ), stu as (
    select s.profile_id, p.full_name, p.email, s.student_reg_no, coalesce(nullif(btrim(s.programme), ''), 'Not set') as programme,
           (pl.student_id is not null) as is_placed, coalesce(a.n, 0) as applications
      from students s
      join profiles p on p.profile_id = s.profile_id and p.email not like '%@deleted.invalid'
      left join placed pl on pl.student_id = s.profile_id
      left join applied a on a.student_id = s.profile_id
  )
  select jsonb_build_object(
    'students_total',       (select count(*) from stu),
    'students_placed',      (select count(*) from stu where is_placed),
    'students_applied',     (select count(*) from stu where applications > 0),
    'applications_total',   (select count(*) from applications),
    'by_status',            coalesce((select jsonb_object_agg(status, n) from (select status, count(*) n from applications group by status) t), '{}'::jsonb),
    'by_programme',         coalesce((select jsonb_agg(jsonb_build_object('programme', programme, 'students', students, 'placed', placed))
                                        from (select programme, count(*) students, count(*) filter (where is_placed) placed from stu group by programme order by count(*) desc) t), '[]'::jsonb),
    'by_company',           coalesce((select jsonb_agg(jsonb_build_object('company', name, 'postings', postings, 'applications', applications, 'placed', placed))
                                        from (select c.name,
                                                     count(distinct jp.job_posting_id) postings,
                                                     count(a.application_id) applications,
                                                     count(a.application_id) filter (where a.status = 'active') placed
                                                from companies c
                                                left join job_postings jp on jp.company_id = c.company_id
                                                left join applications a on a.job_posting_id = jp.job_posting_id
                                               group by c.company_id, c.name
                                               order by count(a.application_id) desc, c.name) t), '[]'::jsonb),
    'top_postings',         coalesce((select jsonb_agg(jsonb_build_object('title', title, 'company', company, 'applications', applications, 'offered', offered, 'placed', placed))
                                        from (select jp.title, c.name as company,
                                                     count(a.application_id) applications,
                                                     count(a.application_id) filter (where a.status in ('offered', 'active')) offered,
                                                     count(a.application_id) filter (where a.status = 'active') placed
                                                from job_postings jp
                                                join companies c on c.company_id = jp.company_id
                                                left join applications a on a.job_posting_id = jp.job_posting_id
                                               group by jp.job_posting_id, jp.title, c.name
                                               order by count(a.application_id) desc, jp.title
                                               limit 20) t), '[]'::jsonb),
    'unplaced_students',    coalesce((select jsonb_agg(jsonb_build_object('name', full_name, 'email', email, 'reg_no', student_reg_no, 'programme', programme, 'applications', applications)
                                        order by full_name)
                                        from stu where not is_placed), '[]'::jsonb)
  ) into v;

  return v;
end;
$$;

revoke all on function public.admin_placement_report() from public, anon;
grant execute on function public.admin_placement_report() to authenticated;
