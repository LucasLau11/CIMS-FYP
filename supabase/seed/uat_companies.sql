-- UAT seed: 12 verified companies in 3 fields of work (4 each), each with one HR account and one
-- company supervisor account, and 1-3 job postings per company in different states (open with a
-- far or a near deadline, open with no deadline, closed after its deadline, closed by hand).
--
-- Every account below is approved, confirmed and already usable, and shares this password:
--     Cims@2026!
-- Emails: hr@<slug>.com.my and supervisor@<slug>.com.my, e.g. hr@nexatech.com.my
--
-- Safe to run twice: a company, user or posting that already exists is left alone.
-- Remove it all again with supabase/seed/uat_companies_remove.sql.

do $$
declare
  pw constant text := 'Cims@2026!';
  c record;
  p record;
  v_company uuid;
  v_category uuid;
  v_uid uuid;
  v_email text;
  v_kind text;
  v_name text;
begin
  for c in
    select * from (values
      -- name, industry, city, slug, hr name, supervisor name
      ('NexaTech Solutions',        'Information Technology', 'Kuala Lumpur, Malaysia',  'nexatech',    'Farah Zainal',      'Daniel Lim Wei Jie'),
      ('CloudBridge Networks',      'Information Technology', 'Petaling Jaya, Malaysia', 'cloudbridge', 'Nurul Huda Aziz',   'Rajesh a/l Kumar'),
      ('SecureNet Systems',         'Information Technology', 'Cyberjaya, Malaysia',     'securenet',   'Tan Mei Ling',      'Haziq bin Rosli'),
      ('PixelForge Studios',        'Information Technology', 'Penang, Malaysia',        'pixelforge',  'Chong Jia Wen',     'Aisyah binti Hamid'),
      ('Meridian Capital Advisory', 'Business & Finance',     'Kuala Lumpur, Malaysia',  'meridian',    'Priya a/p Nair',    'Lee Chun Kit'),
      ('Orchid Trading Sdn Bhd',    'Business & Finance',     'Johor Bahru, Malaysia',   'orchid',      'Siti Rahmah Yusof', 'Wong Kah Hou'),
      ('BrightPath Consulting',     'Business & Finance',     'Shah Alam, Malaysia',     'brightpath',  'Amirul Hakim',      'Kavitha a/p Subramaniam'),
      ('Harbour Logistics Berhad',  'Business & Finance',     'Port Klang, Malaysia',    'harbour',     'Ong Siew Lan',      'Zulkifli bin Ahmad'),
      ('DeepVector AI Labs',        'Computer Science & AI',  'Cyberjaya, Malaysia',     'deepvector',  'Dr Hui Ying Goh',   'Irfan bin Kamal'),
      ('QuantaSoft Research',       'Computer Science & AI',  'Kuala Lumpur, Malaysia',  'quantasoft',  'Sarah Abdullah',    'Teo Zi Xuan'),
      ('Cortex Data Labs',          'Computer Science & AI',  'Penang, Malaysia',        'cortex',      'Muthu a/l Raman',   'Nadia binti Ismail'),
      ('AlgoWorks Technologies',    'Computer Science & AI',  'Petaling Jaya, Malaysia', 'algoworks',   'Lim Shu Fen',       'Faiz bin Hassan')
    ) as t(name, industry, city, slug, hr_name, sup_name)
  loop
    select company_id into v_company from companies where name = c.name;
    if v_company is null then
      insert into companies (name, industry, location, hr_contact_name, hr_contact_email, hr_contact_phone, status)
      values (c.name, c.industry, c.city, c.hr_name, 'hr@' || c.slug || '.com.my',
              '03-' || (7000 + (random() * 2999)::int) || ' ' || (1000 + (random() * 8999)::int), 'verified')
      returning company_id into v_company;
    end if;

    foreach v_kind in array array['hr', 'supervisor'] loop
      v_email := v_kind || '@' || c.slug || '.com.my';
      v_name := case v_kind when 'hr' then c.hr_name else c.sup_name end;
      if exists (select 1 from auth.users where email = v_email) then
        continue;
      end if;
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
                           'full_name', v_name,
                           'app_role', case v_kind when 'hr' then 'company_hr' else 'company_supervisor' end),
        now(), now(), '', '', '', '', '', '', '', '');
      insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      values (gen_random_uuid(), v_uid, v_uid::text,
              jsonb_build_object('sub', v_uid::text, 'email', v_email, 'email_verified', false, 'phone_verified', false),
              'email', now(), now(), now());

      if v_kind = 'hr' then
        update company_hr set company_id = v_company where profile_id = v_uid;
      else
        update company_supervisors set company_id = v_company where profile_id = v_uid;
      end if;
      update profiles set phone = '01' || (1 + (random() * 8)::int) || '-' || (100 + (random() * 899)::int) || ' ' || (1000 + (random() * 8999)::int)
       where profile_id = v_uid;
    end loop;
  end loop;

  -- postings: company slug, title, category, job type, months, allowance, skills, deadline in days from today
  -- (null = no deadline), status
  for p in
    select * from (values
      ('nexatech',    'Full-Stack Web Developer Intern',   'Software', 'Hybrid',  6, 1200, array['JavaScript','React','Node.js','SQL'],           45,   'open'),
      ('nexatech',    'QA Automation Intern',               'Software', 'On-site', 4,  900, array['Testing','Selenium','Python'],                   3,    'open'),
      ('nexatech',    'Mobile App Developer Intern',        'Software', 'Hybrid',  6, 1100, array['Flutter','Dart','Firebase'],                     -20,  'closed'),
      ('cloudbridge', 'Cloud Infrastructure Intern',        'Network',  'On-site', 5, 1300, array['AWS','Linux','Docker','Networking'],             30,   'open'),
      ('cloudbridge', 'Network Support Intern',             'Network',  'On-site', 4,  800, array['Networking','Troubleshooting','Linux'],           null, 'open'),
      ('securenet',   'Cybersecurity Analyst Intern',       'Network',  'On-site', 6, 1400, array['Security','Linux','Python','Networking'],         21,   'open'),
      ('securenet',   'Penetration Testing Intern',         'Network',  'Hybrid',  4, 1250, array['Security','Kali Linux','Python'],                -7,   'closed'),
      ('pixelforge',  'UI/UX Design Intern',                'Design',   'Hybrid',  4,  950, array['Figma','UI/UX','Photoshop'],                     14,   'open'),
      ('pixelforge',  'Game Developer Intern',              'Software', 'On-site', 6, 1150, array['Unity','C#','Git'],                              60,   'open'),
      ('pixelforge',  '3D Asset Artist Intern',             'Design',   'On-site', 3,  850, array['Blender','Photoshop'],                            0,    'closed'),
      ('meridian',    'Financial Analyst Intern',           'Business', 'On-site', 6, 1200, array['Excel','Financial Analysis','PowerPoint'],        40,   'open'),
      ('meridian',    'Audit and Compliance Intern',        'Business', 'On-site', 4, 1000, array['Excel','Accounting','Communication'],             5,    'open'),
      ('orchid',      'Supply Chain Intern',                'Business', 'On-site', 5,  950, array['Excel','Project Management','Communication'],     null, 'open'),
      ('orchid',      'Sales and Marketing Intern',         'Business', 'Hybrid',  4,  850, array['Marketing','Communication','PowerPoint'],         -15,  'closed'),
      ('brightpath',  'Business Analyst Intern',            'Business', 'Hybrid',  6, 1300, array['Data Analysis','Excel','Power BI','SQL'],        28,   'open'),
      ('brightpath',  'Human Resources Intern',             'Business', 'On-site', 4,  900, array['Communication','Excel','Teamwork'],               35,   'open'),
      ('brightpath',  'Project Coordinator Intern',         'Business', 'Remote',  3,  800, array['Project Management','Communication'],             10,   'closed'),
      ('harbour',     'Logistics Operations Intern',        'Business', 'On-site', 5,  900, array['Excel','Communication','Teamwork'],                25,   'open'),
      ('harbour',     'Procurement Assistant Intern',       'Business', 'On-site', 4,  850, array['Excel','Negotiation'],                            -30,  'closed'),
      ('deepvector',  'Machine Learning Engineer Intern',   'Data',     'Hybrid',  6, 1600, array['Python','TensorFlow','Machine Learning','SQL'],   50,   'open'),
      ('deepvector',  'Computer Vision Research Intern',    'Data',     'On-site', 6, 1500, array['Python','OpenCV','Machine Learning'],              7,    'open'),
      ('deepvector',  'NLP Engineer Intern',                'Data',     'Hybrid',  5, 1550, array['Python','NLP','Hugging Face Transformers'],       -10,  'closed'),
      ('quantasoft',  'Algorithm Research Intern',          'Software', 'On-site', 6, 1450, array['Python','Algorithms','Data Structures'],          33,   'open'),
      ('quantasoft',  'Backend Developer Intern',           'Software', 'Hybrid',  5, 1200, array['Java','SQL','Docker','Git'],                      null, 'open'),
      ('cortex',      'Data Engineer Intern',               'Data',     'Hybrid',  6, 1350, array['Python','SQL','Spark','AWS'],                     42,   'open'),
      ('cortex',      'Data Visualisation Intern',          'Data',     'On-site', 4, 1000, array['Tableau','Power BI','SQL'],                       4,    'open'),
      ('cortex',      'Business Intelligence Intern',       'Data',     'On-site', 4, 1050, array['SQL','Power BI','Excel'],                         -25,  'closed'),
      ('algoworks',   'Software Engineering Intern',        'Software', 'Hybrid',  6, 1250, array['Java','Git','Agile','SQL'],                       20,   'open'),
      ('algoworks',   'DevOps Intern',                      'Software', 'On-site', 4, 1150, array['Docker','Kubernetes','Linux','CI/CD'],             18,   'closed')
    ) as t(slug, title, category, job_type, months, allowance, skills, deadline_in_days, status)
  loop
    select company_id into v_company from companies where hr_contact_email = 'hr@' || p.slug || '.com.my';
    select category_id into v_category from categories where category_name = p.category;
    if v_company is null or exists (select 1 from job_postings where company_id = v_company and title = p.title) then
      continue;
    end if;
    insert into job_postings (company_id, category_id, status, title, description, location, duration_months, allowance_month,
                              required_skills, job_type, application_deadline, posted_at)
    values (
      v_company, v_category, p.status, p.title,
      'Join our team as a ' || lower(p.title) || '. You will work on real projects with a mentor, join team meetings and present your '
        || 'work at the end of the internship. Suitable for final-year diploma and degree students.',
      (select location from companies where company_id = v_company), p.months, p.allowance, p.skills, p.job_type,
      case when p.deadline_in_days is null then null else (current_date + p.deadline_in_days) end,
      now() - ((random() * 25)::int || ' days')::interval);
  end loop;
end $$;
