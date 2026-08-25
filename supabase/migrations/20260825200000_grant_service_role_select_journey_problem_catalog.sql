-- المرافقة الكاملة والاستمارة (miniapp) تقرأ هذا الجدول بـ service_role مباشرة
-- (لا عبر RPC)، وكان بلا أي GRANT لـservice_role إطلاقاً — هذا سبب فشل
-- /api/wizard/catalog بـ 500 (permission denied) فالإنتاج، رغم أن الاستعلام
-- نفسه صحيح 100% وباقي الجداول (daily_logs، followers) عندها هذا الـGRANT.
-- طُبّق مباشرة على قاعدة البيانات؛ هذا الملف فقط لتوثيقه بتاريخ الـmigrations.
grant select on public.journey_problem_catalog to service_role;
