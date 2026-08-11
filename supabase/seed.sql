-- Optional Sprint 1 development seed. Run after both migrations and after an ADMIN exists.
do $$
declare admin_id uuid;
begin
  select id into admin_id from public.profiles where role = 'ADMIN' and status = 'ACTIVE' order by created_at limit 1;
  if admin_id is null then raise exception 'Create an ACTIVE ADMIN profile before running seed.sql'; end if;

  insert into public.businesses (id, legal_name, brand_name, inn, website, domain, description, verification_status) values
    ('10000000-0000-4000-8000-000000000001', 'ООО Правовой Контур', 'Правовой Контур', 'SEED7700000001', 'https://legal.example', 'legal.example', 'Юридический аутсорсинг для растущих B2B-компаний.', 'VERIFIED'),
    ('10000000-0000-4000-8000-000000000002', 'ООО Талант Флоу', 'TalentFlow', 'SEED7700000002', 'https://hr.example', 'hr.example', 'HR-tech SaaS для автоматизации найма и адаптации.', 'VERIFIED'),
    ('10000000-0000-4000-8000-000000000003', 'ООО Логистик ОС', 'LogisticOS', 'SEED7700000003', 'https://logistics.example', 'logistics.example', 'Автоматизация транспортной логистики и маршрутизации.', 'VERIFIED'),
    ('10000000-0000-4000-8000-000000000004', 'ООО Интегра Лаб', 'IntegraLab', 'SEED7700000004', 'https://integrator.example', 'integrator.example', 'Корпоративный IT-интегратор и разработчик внутренних систем.', 'VERIFIED'),
    ('10000000-0000-4000-8000-000000000005', 'ООО Маркет Пульс', 'MarketPulse', 'SEED7700000005', 'https://marketing.example', 'marketing.example', 'B2B marketing SaaS для аналитики контента и pipeline.', 'VERIFIED')
  on conflict (id) do nothing;

  insert into public.bounties (
    id, business_id, title, slug, summary, product_description, sales_website,
    reward_amount, platform_fee_amount, meeting_limit, status, active_until,
    minimum_duration_minutes, meeting_format, existing_crm_rule, acceptance_notes,
    created_by, approved_by, current_version, published_at
  ) values
    ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Встреча с руководителем юридической функции', 'legal-outsourcing-counsel', 'Ищем встречи с компаниями, которым требуется регулярная внешняя юридическая поддержка.', 'Абонентское юридическое сопровождение договорной и корпоративной работы.', 'https://legal.example', 4500000, 700000, 8, 'ACTIVE', now() + interval '60 days', 30, 'ONLINE', 'Нет активной opportunity или содержательной коммуникации за последние 90 дней.', '', admin_id, admin_id, 1, now()),
    ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'Демо HR-tech платформы для Head of HR', 'hr-tech-head-of-hr', 'Встречи с HR-руководителями компаний, активно нанимающих специалистов.', 'SaaS для управления наймом, адаптацией и аналитикой HR-процессов.', 'https://hr.example', 3000000, 500000, 15, 'ACTIVE', now() + interval '45 days', 30, 'ONLINE', 'Нет активной opportunity или содержательной коммуникации за последние 90 дней.', '', admin_id, admin_id, 1, now()),
    ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003', 'Автоматизация логистики для грузовладельцев', 'logistics-automation', 'Нужны встречи с руководителями логистики средних и крупных производителей.', 'Платформа маршрутизации, контроля перевозчиков и снижения пустого пробега.', 'https://logistics.example', 6000000, 900000, 6, 'ACTIVE', now() + interval '75 days', 45, 'BOTH', 'Нет активной opportunity или содержательной коммуникации за последние 90 дней.', 'Встреча должна включать обсуждение текущего транспортного контура.', admin_id, admin_id, 1, now()),
    ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000004', 'IT-интеграция для промышленности', 'industrial-it-integration', 'Встречи с IT-директорами промышленных предприятий с планом цифровизации.', 'Проектирование интеграционной архитектуры и разработка корпоративных систем.', 'https://integrator.example', 8000000, 1200000, 5, 'ACTIVE', now() + interval '90 days', 45, 'ONLINE', 'Нет активной opportunity или содержательной коммуникации за последние 90 дней.', '', admin_id, admin_id, 1, now()),
    ('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000005', 'B2B marketing analytics для SaaS-команд', 'b2b-marketing-saas', 'Ищем маркетинг-руководителей B2B SaaS с системным контент-маркетингом.', 'Аналитика влияния B2B-контента на pipeline и атрибуция касаний.', 'https://marketing.example', 2500000, 400000, 12, 'ACTIVE', now() + interval '40 days', 30, 'ONLINE', 'Нет активной opportunity или содержательной коммуникации за последние 90 дней.', '', admin_id, admin_id, 1, now())
  on conflict (id) do nothing;

  insert into public.bounty_icp (bounty_id, geography, industries, excluded_industries, min_revenue, max_revenue, min_employees, max_employees, allowed_roles, excluded_company_inns, hard_rules, soft_notes) values
    ('20000000-0000-4000-8000-000000000001', array['Россия'], array['SaaS','IT','Профессиональные услуги'], array['Микробизнес'], 300000000, null, 100, null, array['Генеральный директор','Директор по правовым вопросам'], '{}', 'Есть регулярный объём договорной или корпоративной работы.', 'Приоритет компаниям в стадии быстрого роста.'),
    ('20000000-0000-4000-8000-000000000002', array['Россия','Казахстан'], array['IT','Финтех','E-commerce'], '{}', 500000000, null, 200, 5000, array['HRD','Head of Talent Acquisition'], '{}', 'Не менее 20 открытых вакансий или 10 наймов в месяц.', 'Интересны распределённые команды.'),
    ('20000000-0000-4000-8000-000000000003', array['ЦФО','ПФО','УФО'], array['Производство','FMCG','Дистрибуция'], array['Такси'], 2000000000, null, 300, null, array['Директор по логистике','Операционный директор'], '{}', 'Компания самостоятельно управляет регулярными грузоперевозками.', 'Желателен собственный или контрактный парк.'),
    ('20000000-0000-4000-8000-000000000004', array['Россия'], array['Промышленность','Энергетика'], '{}', 5000000000, null, 500, null, array['CIO','IT-директор','Директор по цифровизации'], '{}', 'Есть утверждённая или планируемая программа цифровизации.', 'Особенно интересны проекты интеграции ERP/MES.'),
    ('20000000-0000-4000-8000-000000000005', array['Россия','СНГ'], array['B2B SaaS','MarTech'], array['B2C-only'], 100000000, 3000000000, 50, 1000, array['CMO','Head of Marketing','Demand Generation Lead'], '{}', 'Есть B2B sales pipeline и регулярный контент-маркетинг.', 'Приоритет командам с длинным циклом сделки.')
  on conflict (bounty_id) do nothing;

  insert into public.bounty_materials (bounty_id, label, content, material_type, sort_order)
  select id, 'Боли и триггеры', 'Ручные процессы, отсутствие прозрачной аналитики и высокая стоимость текущего процесса.', 'PAINS', 10 from public.bounties where id::text like '20000000-0000-4000-8000-%'
  on conflict do nothing;
  insert into public.bounty_materials (bounty_id, label, content, material_type, sort_order)
  select id, 'Ценностные предложения', 'Покажите измеримый эффект, быстрый старт пилота и понятный процесс внедрения.', 'VALUE_PROPOSITIONS', 20 from public.bounties where id::text like '20000000-0000-4000-8000-%'
  on conflict do nothing;
  insert into public.bounty_materials (bounty_id, label, content, material_type, sort_order)
  select id, 'Рекомендации по аутричу', 'Не обещайте гарантированный финансовый результат. Начните с релевантного операционного триггера.', 'OUTREACH_NOTES', 30 from public.bounties where id::text like '20000000-0000-4000-8000-%'
  on conflict do nothing;

  insert into public.bounty_versions (bounty_id, version, snapshot, created_by)
  select b.id, 1, jsonb_build_object('bounty', to_jsonb(b), 'icp', to_jsonb(i), 'materials', coalesce((select jsonb_agg(to_jsonb(m) order by m.sort_order) from public.bounty_materials m where m.bounty_id = b.id), '[]'::jsonb)), admin_id
  from public.bounties b join public.bounty_icp i on i.bounty_id = b.id
  where b.id::text like '20000000-0000-4000-8000-%'
  on conflict (bounty_id, version) do nothing;
end $$;
