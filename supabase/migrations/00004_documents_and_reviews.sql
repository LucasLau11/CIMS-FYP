-- Task 5: Documents + document reviews.
-- Students upload documents (offer letters, indemnity letters, etc.);
-- document review is internal to the school -- academic supervisors and
-- admins can review, company_supervisor is deliberately excluded from
-- document_reviews write access. This is an intentional boundary
-- confirmed earlier in the project, not an oversight.

create table documents (
  document_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(profile_id),
  category text not null check (category in ('offer_letter','indemnity_letter','company_acceptance_letter','insurance_certificate','other')),
  status text not null default 'submitted' check (status in ('submitted','approved','rejected')),
  title text,
  storage_path text not null,
  file_name text not null,
  file_size_bytes bigint not null,
  uploaded_at timestamptz not null default now()
);

create table document_reviews (
  document_review_id uuid primary key default gen_random_uuid(),
  document_id uuid not null unique references documents(document_id),
  reviewer_id uuid references profiles(profile_id),
  feedback text,
  reviewed_at timestamptz
);

alter table documents enable row level security;
alter table document_reviews enable row level security;

create policy documents_select_involved on documents for select to authenticated
  using (student_id = (select auth.uid()) or (select current_user_role()) = 'admin'
         or is_academic_supervisor_of(student_id) or is_approved_parent_of(student_id));
create policy documents_insert_own on documents for insert to authenticated with check (student_id = (select auth.uid()));
create policy documents_update_supervisor on documents for update to authenticated
  using ((select current_user_role()) = 'admin' or is_academic_supervisor_of(student_id) or student_id = (select auth.uid()));

create policy document_reviews_select_involved on document_reviews for select to authenticated
  using (exists (select 1 from documents d where d.document_id = document_reviews.document_id
                 and (d.student_id = (select auth.uid()) or (select current_user_role()) = 'admin' or is_academic_supervisor_of(d.student_id))));

create or replace function can_manage_document_review(p_document_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select (select current_user_role()) = 'admin'
         or exists (select 1 from documents d where d.document_id = p_document_id and is_academic_supervisor_of(d.student_id));
$$;
revoke execute on function can_manage_document_review(uuid) from public, anon;
grant execute on function can_manage_document_review(uuid) to authenticated;

create policy document_reviews_insert_academic_or_admin on document_reviews for insert to authenticated
  with check (can_manage_document_review(document_id));
create policy document_reviews_update_academic_or_admin on document_reviews for update to authenticated
  using (can_manage_document_review(document_id)) with check (can_manage_document_review(document_id));
create policy document_reviews_delete_academic_or_admin on document_reviews for delete to authenticated
  using (can_manage_document_review(document_id));

create index if not exists idx_documents_student_id on documents(student_id);
create index if not exists idx_document_reviews_reviewer_id on document_reviews(reviewer_id);
