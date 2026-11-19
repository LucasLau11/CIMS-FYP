-- 00035: run the maintenance functions on a timer with pg_cron.
--   * every 5 minutes: interview reminders (24h and 1h before) and marking past interviews completed
--   * every 15 minutes: closing postings whose deadline has passed
-- Re-running this file replaces the two jobs rather than adding duplicates.

create extension if not exists pg_cron;

select cron.unschedule(jobid) from cron.job where jobname in ('cims-interview-maintenance', 'cims-close-expired-postings');

select cron.schedule('cims-interview-maintenance', '*/5 * * * *', $$select public.run_interview_maintenance()$$);
select cron.schedule('cims-close-expired-postings', '*/15 * * * *', $$select public.close_expired_postings()$$);
