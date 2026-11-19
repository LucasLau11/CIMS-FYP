-- UAT seed: one ready-to-use student account (approved, email confirmed, no password change asked at login).
--
--     email     uat.student@student.tarc.edu.my
--     password  Cims@2026!          (the same password as the seeded company accounts)
--
-- A complete profile (programme, faculty, semester, CGPA, skills, phone, birth date, address and one work
-- experience) in the "June 2025" intake. No academic supervisor is assigned, so the administrator can try the
-- assignment, and no application exists yet, so the whole flow (apply, interview, offer, accept) can be tried.
--
-- Safe to run twice: an existing account is left alone.

do $$
declare
  pw constant text := 'Cims@2026!';
  v_email constant text := 'uat.student@student.tarc.edu.my';
  v_name constant text := 'Aiman Hakim bin Razak';
  v_uid uuid;
  v_intake uuid;
begin
  if exists (select 1 from auth.users where email = v_email) then
    raise notice 'uat student already exists';
    return;
  end if;

  select intake_id into v_intake from intakes where name = 'June 2025' limit 1;

  v_uid := gen_random_uuid();
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token, phone_change, phone_change_token)
  values (
    '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated', v_email,
    extensions.crypt(pw, extensions.gen_salt('bf', 10)), now(),
    -- created_by_admin makes the sign-up trigger approve the account straight away
    '{"provider":"email","providers":["email"],"created_by_admin":true}'::jsonb,
    jsonb_build_object('sub', v_uid::text, 'email', v_email, 'email_verified', true, 'phone_verified', false,
                       'full_name', v_name, 'app_role', 'student'),
    now(), now(), '', '', '', '', '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  values (gen_random_uuid(), v_uid, v_uid::text,
          jsonb_build_object('sub', v_uid::text, 'email', v_email, 'email_verified', false, 'phone_verified', false),
          'email', now(), now(), now());

  update profiles
     set full_name = v_name,
         phone = '012-345 6789',
         date_of_birth = date '2003-05-14',
         address_text = 'No. 18, Jalan Genting Klang, 53300 Setapak, Kuala Lumpur',
         language = 'en',
         approval_status = 'approved',
         must_change_password = false
   where profile_id = v_uid;

  update students
     set programme = 'Bachelor of Information Technology (Honours) in Software Systems Development',
         faculty = 'Faculty of Computing and Information Technology',
         semester = 3,
         cgpa = 3.45,
         skills = array['Python', 'Java', 'SQL', 'Flutter', 'Git', 'Problem Solving'],
         student_reg_no = '25PMR99001',
         intake_id = v_intake
   where profile_id = v_uid;

  insert into work_experiences (student_id, position, company_name, start_year, end_year, is_current, description)
  values (v_uid, 'IT Support Assistant', 'TechNova Sdn Bhd', 2024, 2024, false,
          'Helped staff with daily IT requests and prepared simple reports.');
end $$;
