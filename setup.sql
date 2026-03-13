-- ═══════════════════════════════════════════════
-- 구좌마을여행사협동조합 Supabase Setup
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════

-- 1. EMPLOYEES
CREATE TABLE IF NOT EXISTS employees (
  id BIGINT PRIMARY KEY,
  name TEXT NOT NULL,
  avatar TEXT NOT NULL,
  color_class TEXT NOT NULL DEFAULT 'c1',
  position TEXT NOT NULL DEFAULT '매니저'
);

-- 2. PROFILES (linked to auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin','emp')),
  name TEXT NOT NULL,
  employee_id BIGINT REFERENCES employees(id),
  avatar TEXT NOT NULL,
  color_class TEXT NOT NULL DEFAULT 'c1'
);

-- 3. SCHEDULES
CREATE TABLE IF NOT EXISTS schedules (
  id BIGSERIAL PRIMARY KEY,
  month_key TEXT NOT NULL,
  day INT NOT NULL CHECK (day BETWEEN 1 AND 31),
  employee_id BIGINT NOT NULL REFERENCES employees(id),
  site_code TEXT NOT NULL DEFAULT 'OFF',
  UNIQUE (month_key, day, employee_id)
);
CREATE INDEX IF NOT EXISTS idx_sch_month ON schedules(month_key);

-- 4. EVENTS
CREATE TABLE IF NOT EXISTS events (
  id BIGSERIAL PRIMARY KEY,
  event_date DATE NOT NULL UNIQUE,
  event_name TEXT NOT NULL
);

-- 5. LEAVE BALANCES
CREATE TABLE IF NOT EXISTS leave_balances (
  id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL REFERENCES employees(id),
  used NUMERIC(4,1) NOT NULL DEFAULT 0,
  annual NUMERIC(4,1) NOT NULL DEFAULT 10,
  year INT NOT NULL DEFAULT 2026,
  UNIQUE (employee_id, year)
);

-- 6. LEAVE REQUESTS
CREATE TABLE IF NOT EXISTS leave_requests (
  id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL REFERENCES employees(id),
  emp_name TEXT NOT NULL,
  leave_type TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days NUMERIC(4,1) NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ═══ RLS ═══
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;

-- Helper functions
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_user_employee_id()
RETURNS BIGINT AS $$
  SELECT employee_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- EMPLOYEES
CREATE POLICY "emp_read" ON employees FOR SELECT TO authenticated USING (true);
CREATE POLICY "emp_admin" ON employees FOR ALL TO authenticated USING (get_user_role()='admin') WITH CHECK (get_user_role()='admin');

-- PROFILES
CREATE POLICY "prof_read" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "prof_admin" ON profiles FOR ALL TO authenticated USING (get_user_role()='admin') WITH CHECK (get_user_role()='admin');

-- SCHEDULES
CREATE POLICY "sch_read" ON schedules FOR SELECT TO authenticated USING (true);
CREATE POLICY "sch_insert" ON schedules FOR INSERT TO authenticated WITH CHECK (get_user_role()='admin');
CREATE POLICY "sch_update" ON schedules FOR UPDATE TO authenticated USING (get_user_role()='admin');
CREATE POLICY "sch_delete" ON schedules FOR DELETE TO authenticated USING (get_user_role()='admin');

-- EVENTS
CREATE POLICY "evt_read" ON events FOR SELECT TO authenticated USING (true);
CREATE POLICY "evt_insert" ON events FOR INSERT TO authenticated WITH CHECK (get_user_role()='admin');
CREATE POLICY "evt_update" ON events FOR UPDATE TO authenticated USING (get_user_role()='admin');
CREATE POLICY "evt_delete" ON events FOR DELETE TO authenticated USING (get_user_role()='admin');

-- LEAVE BALANCES
CREATE POLICY "lb_read" ON leave_balances FOR SELECT TO authenticated
  USING (employee_id = get_user_employee_id() OR get_user_role()='admin');
CREATE POLICY "lb_admin" ON leave_balances FOR ALL TO authenticated
  USING (get_user_role()='admin') WITH CHECK (get_user_role()='admin');

-- LEAVE REQUESTS
CREATE POLICY "lr_read" ON leave_requests FOR SELECT TO authenticated
  USING (employee_id = get_user_employee_id() OR get_user_role()='admin');
CREATE POLICY "lr_insert" ON leave_requests FOR INSERT TO authenticated
  WITH CHECK (employee_id = get_user_employee_id() OR get_user_role()='admin');
CREATE POLICY "lr_update" ON leave_requests FOR UPDATE TO authenticated
  USING (get_user_role()='admin');
CREATE POLICY "lr_delete" ON leave_requests FOR DELETE TO authenticated
  USING (get_user_role()='admin');

-- ═══ AUTH USERS ═══
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES ('00000000-0000-0000-0000-000000000000', 'a0000001-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'admin@gujwa.local', crypt('gujwa2026!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES ('a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000001', json_build_object('sub','a0000001-0000-0000-0000-000000000001','email','admin@gujwa.local')::jsonb, 'email', 'a0000001-0000-0000-0000-000000000001', now(), now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES ('00000000-0000-0000-0000-000000000000', 'a0000001-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'kimjh@gujwa.local', crypt('jh1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES ('a0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000002', json_build_object('sub','a0000001-0000-0000-0000-000000000002','email','kimjh@gujwa.local')::jsonb, 'email', 'a0000001-0000-0000-0000-000000000002', now(), now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES ('00000000-0000-0000-0000-000000000000', 'a0000001-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'kanghj@gujwa.local', crypt('hj1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES ('a0000001-0000-0000-0000-000000000003', 'a0000001-0000-0000-0000-000000000003', json_build_object('sub','a0000001-0000-0000-0000-000000000003','email','kanghj@gujwa.local')::jsonb, 'email', 'a0000001-0000-0000-0000-000000000003', now(), now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES ('00000000-0000-0000-0000-000000000000', 'a0000001-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'minbj@gujwa.local', crypt('bj1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES ('a0000001-0000-0000-0000-000000000004', 'a0000001-0000-0000-0000-000000000004', json_build_object('sub','a0000001-0000-0000-0000-000000000004','email','minbj@gujwa.local')::jsonb, 'email', 'a0000001-0000-0000-0000-000000000004', now(), now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES ('00000000-0000-0000-0000-000000000000', 'a0000001-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'leesia@gujwa.local', crypt('sia1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES ('a0000001-0000-0000-0000-000000000005', 'a0000001-0000-0000-0000-000000000005', json_build_object('sub','a0000001-0000-0000-0000-000000000005','email','leesia@gujwa.local')::jsonb, 'email', 'a0000001-0000-0000-0000-000000000005', now(), now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES ('00000000-0000-0000-0000-000000000000', 'a0000001-0000-0000-0000-000000000006', 'authenticated', 'authenticated', 'kimsy@gujwa.local', crypt('sy1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES ('a0000001-0000-0000-0000-000000000006', 'a0000001-0000-0000-0000-000000000006', json_build_object('sub','a0000001-0000-0000-0000-000000000006','email','kimsy@gujwa.local')::jsonb, 'email', 'a0000001-0000-0000-0000-000000000006', now(), now(), now());

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES ('00000000-0000-0000-0000-000000000000', 'a0000001-0000-0000-0000-000000000007', 'authenticated', 'authenticated', 'yunhj@gujwa.local', crypt('yhj1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES ('a0000001-0000-0000-0000-000000000007', 'a0000001-0000-0000-0000-000000000007', json_build_object('sub','a0000001-0000-0000-0000-000000000007','email','yunhj@gujwa.local')::jsonb, 'email', 'a0000001-0000-0000-0000-000000000007', now(), now(), now());

-- ═══ SEED EMPLOYEES ═══
INSERT INTO employees (id,name,avatar,color_class,position) VALUES (1,'김지훈','김','c1','매니저');
INSERT INTO employees (id,name,avatar,color_class,position) VALUES (2,'강현진','강','c2','매니저');
INSERT INTO employees (id,name,avatar,color_class,position) VALUES (3,'민병제','민','c3','매니저');
INSERT INTO employees (id,name,avatar,color_class,position) VALUES (4,'이시아','이','c4','매니저');
INSERT INTO employees (id,name,avatar,color_class,position) VALUES (5,'김선영','김','c5','매니저');
INSERT INTO employees (id,name,avatar,color_class,position) VALUES (6,'윤희정','윤','c6','매니저');

-- ═══ SEED PROFILES ═══
INSERT INTO profiles (id,username,role,name,employee_id,avatar,color_class) VALUES ('a0000001-0000-0000-0000-000000000001','admin','admin','관리자',NULL,'관','c1');
INSERT INTO profiles (id,username,role,name,employee_id,avatar,color_class) VALUES ('a0000001-0000-0000-0000-000000000002','kimjh','emp','김지훈',1,'김','c1');
INSERT INTO profiles (id,username,role,name,employee_id,avatar,color_class) VALUES ('a0000001-0000-0000-0000-000000000003','kanghj','emp','강현진',2,'강','c2');
INSERT INTO profiles (id,username,role,name,employee_id,avatar,color_class) VALUES ('a0000001-0000-0000-0000-000000000004','minbj','emp','민병제',3,'민','c3');
INSERT INTO profiles (id,username,role,name,employee_id,avatar,color_class) VALUES ('a0000001-0000-0000-0000-000000000005','leesia','emp','이시아',4,'이','c4');
INSERT INTO profiles (id,username,role,name,employee_id,avatar,color_class) VALUES ('a0000001-0000-0000-0000-000000000006','kimsy','emp','김선영',5,'김','c5');
INSERT INTO profiles (id,username,role,name,employee_id,avatar,color_class) VALUES ('a0000001-0000-0000-0000-000000000007','yunhj','emp','윤희정',6,'윤','c6');

-- ═══ SEED EVENTS ═══
INSERT INTO events (event_date,event_name) VALUES ('2026-01-05','라이즈교육');
INSERT INTO events (event_date,event_name) VALUES ('2026-01-06','라이즈교육');
INSERT INTO events (event_date,event_name) VALUES ('2026-01-08','리서치클러스터');
INSERT INTO events (event_date,event_name) VALUES ('2026-01-09','리서치클러스터');
INSERT INTO events (event_date,event_name) VALUES ('2026-01-10','리서치클러스터');
INSERT INTO events (event_date,event_name) VALUES ('2026-01-11','리서치클러스터');
INSERT INTO events (event_date,event_name) VALUES ('2026-01-23','성과공유');
INSERT INTO events (event_date,event_name) VALUES ('2026-01-24','성과공유');
INSERT INTO events (event_date,event_name) VALUES ('2026-02-05','청소년숙박');
INSERT INTO events (event_date,event_name) VALUES ('2026-02-06','청소년숙박');
INSERT INTO events (event_date,event_name) VALUES ('2026-02-15','설연휴');
INSERT INTO events (event_date,event_name) VALUES ('2026-02-16','설연휴');
INSERT INTO events (event_date,event_name) VALUES ('2026-02-17','설연휴');
INSERT INTO events (event_date,event_name) VALUES ('2026-02-18','설날');
INSERT INTO events (event_date,event_name) VALUES ('2026-02-27','선진지');
INSERT INTO events (event_date,event_name) VALUES ('2026-02-28','선진지');
INSERT INTO events (event_date,event_name) VALUES ('2026-03-01','삼일절');

-- ═══ SEED LEAVE BALANCES ═══
INSERT INTO leave_balances (employee_id,used,annual,year) VALUES (1,1,10,2026);
INSERT INTO leave_balances (employee_id,used,annual,year) VALUES (2,0,10,2026);
INSERT INTO leave_balances (employee_id,used,annual,year) VALUES (3,2,10,2026);
INSERT INTO leave_balances (employee_id,used,annual,year) VALUES (4,0,10,2026);
INSERT INTO leave_balances (employee_id,used,annual,year) VALUES (5,1,10,2026);
INSERT INTO leave_balances (employee_id,used,annual,year) VALUES (6,0,10,2026);

-- ═══ SEED LEAVE REQUESTS ═══
INSERT INTO leave_requests (employee_id,emp_name,leave_type,start_date,end_date,days,reason,status) VALUES (3,'민병제','연차','2026-03-09','2026-03-10',2,'개인사정','approved');
INSERT INTO leave_requests (employee_id,emp_name,leave_type,start_date,end_date,days,reason,status) VALUES (5,'김선영','연차','2026-03-13','2026-03-13',1,'개인사정','approved');
INSERT INTO leave_requests (employee_id,emp_name,leave_type,start_date,end_date,days,reason,status) VALUES (1,'김지훈','연차','2026-03-27','2026-03-27',1,'개인사정','approved');

-- ═══ SEED SCHEDULES ═══
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-01',1,1,'OFF'),
('2026-01',1,2,'OFF'),
('2026-01',1,3,'OFF'),
('2026-01',1,4,'C'),
('2026-01',1,5,'C'),
('2026-01',1,6,'OFF'),
('2026-01',2,1,'A'),
('2026-01',2,2,'B'),
('2026-01',2,3,'B'),
('2026-01',2,4,'OFF'),
('2026-01',2,5,'C'),
('2026-01',2,6,'B'),
('2026-01',3,1,'A'),
('2026-01',3,2,'OFF'),
('2026-01',3,3,'C'),
('2026-01',3,4,'C'),
('2026-01',3,5,'OFF'),
('2026-01',3,6,'A'),
('2026-01',4,1,'OFF'),
('2026-01',4,2,'A'),
('2026-01',4,3,'A'),
('2026-01',4,4,'C'),
('2026-01',4,5,'OFF'),
('2026-01',4,6,'OFF'),
('2026-01',5,1,'OFF'),
('2026-01',5,2,'B'),
('2026-01',5,3,'OFF'),
('2026-01',5,4,'A'),
('2026-01',5,5,'C'),
('2026-01',5,6,'B'),
('2026-01',6,1,'A'),
('2026-01',6,2,'OFF'),
('2026-01',6,3,'OFF'),
('2026-01',6,4,'OFF'),
('2026-01',6,5,'C'),
('2026-01',6,6,'B'),
('2026-01',7,1,'A'),
('2026-01',7,2,'B'),
('2026-01',7,3,'B'),
('2026-01',7,4,'OFF'),
('2026-01',7,5,'C'),
('2026-01',7,6,'B'),
('2026-01',8,1,'A'),
('2026-01',8,2,'B'),
('2026-01',8,3,'B'),
('2026-01',8,4,'C'),
('2026-01',8,5,'C'),
('2026-01',8,6,'OFF'),
('2026-01',9,1,'A'),
('2026-01',9,2,'B');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-01',9,3,'B'),
('2026-01',9,4,'C'),
('2026-01',9,5,'OFF'),
('2026-01',9,6,'B'),
('2026-01',10,1,'A'),
('2026-01',10,2,'OFF'),
('2026-01',10,3,'C'),
('2026-01',10,4,'C'),
('2026-01',10,5,'OFF'),
('2026-01',10,6,'A'),
('2026-01',11,1,'OFF'),
('2026-01',11,2,'A'),
('2026-01',11,3,'OFF'),
('2026-01',11,4,'C'),
('2026-01',11,5,'OFF'),
('2026-01',11,6,'OFF'),
('2026-01',12,1,'OFF'),
('2026-01',12,2,'B'),
('2026-01',12,3,'OFF'),
('2026-01',12,4,'A'),
('2026-01',12,5,'C'),
('2026-01',12,6,'B'),
('2026-01',13,1,'A'),
('2026-01',13,2,'OFF'),
('2026-01',13,3,'OFF'),
('2026-01',13,4,'OFF'),
('2026-01',13,5,'C'),
('2026-01',13,6,'OFF'),
('2026-01',14,1,'A'),
('2026-01',14,2,'B'),
('2026-01',14,3,'B'),
('2026-01',14,4,'OFF'),
('2026-01',14,5,'C'),
('2026-01',14,6,'B'),
('2026-01',15,1,'A'),
('2026-01',15,2,'B'),
('2026-01',15,3,'B'),
('2026-01',15,4,'C'),
('2026-01',15,5,'C'),
('2026-01',15,6,'B'),
('2026-01',16,1,'A'),
('2026-01',16,2,'B'),
('2026-01',16,3,'B'),
('2026-01',16,4,'C'),
('2026-01',16,5,'C'),
('2026-01',16,6,'B'),
('2026-01',17,1,'A'),
('2026-01',17,2,'B'),
('2026-01',17,3,'B'),
('2026-01',17,4,'C');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-01',17,5,'C'),
('2026-01',17,6,'B'),
('2026-01',18,1,'A'),
('2026-01',18,2,'OFF'),
('2026-01',18,3,'C'),
('2026-01',18,4,'C'),
('2026-01',18,5,'C'),
('2026-01',18,6,'A'),
('2026-01',19,1,'OFF'),
('2026-01',19,2,'A'),
('2026-01',19,3,'C'),
('2026-01',19,4,'C'),
('2026-01',19,5,'OFF'),
('2026-01',19,6,'OFF'),
('2026-01',20,1,'OFF'),
('2026-01',20,2,'B'),
('2026-01',20,3,'OFF'),
('2026-01',20,4,'A'),
('2026-01',20,5,'C'),
('2026-01',20,6,'B'),
('2026-01',21,1,'A'),
('2026-01',21,2,'OFF'),
('2026-01',21,3,'OFF'),
('2026-01',21,4,'OFF'),
('2026-01',21,5,'C'),
('2026-01',21,6,'OFF'),
('2026-01',22,1,'A'),
('2026-01',22,2,'B'),
('2026-01',22,3,'B'),
('2026-01',22,4,'OFF'),
('2026-01',22,5,'C'),
('2026-01',22,6,'B'),
('2026-01',23,1,'A'),
('2026-01',23,2,'B'),
('2026-01',23,3,'B'),
('2026-01',23,4,'C'),
('2026-01',23,5,'C'),
('2026-01',23,6,'B'),
('2026-01',24,1,'A'),
('2026-01',24,2,'B'),
('2026-01',24,3,'B'),
('2026-01',24,4,'C'),
('2026-01',24,5,'C'),
('2026-01',24,6,'B'),
('2026-01',25,1,'A'),
('2026-01',25,2,'OFF'),
('2026-01',25,3,'C'),
('2026-01',25,4,'C'),
('2026-01',25,5,'OFF'),
('2026-01',25,6,'B');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-01',26,1,'OFF'),
('2026-01',26,2,'A'),
('2026-01',26,3,'A'),
('2026-01',26,4,'C'),
('2026-01',26,5,'OFF'),
('2026-01',26,6,'B'),
('2026-01',27,1,'OFF'),
('2026-01',27,2,'A'),
('2026-01',27,3,'OFF'),
('2026-01',27,4,'C'),
('2026-01',27,5,'OFF'),
('2026-01',27,6,'B'),
('2026-01',28,1,'A'),
('2026-01',28,2,'B'),
('2026-01',28,3,'B'),
('2026-01',28,4,'A'),
('2026-01',28,5,'C'),
('2026-01',28,6,'B'),
('2026-01',29,1,'A'),
('2026-01',29,2,'OFF'),
('2026-01',29,3,'B'),
('2026-01',29,4,'OFF'),
('2026-01',29,5,'C'),
('2026-01',29,6,'OFF'),
('2026-01',30,1,'A'),
('2026-01',30,2,'B'),
('2026-01',30,3,'B'),
('2026-01',30,4,'OFF'),
('2026-01',30,5,'C'),
('2026-01',30,6,'B'),
('2026-01',31,1,'A'),
('2026-01',31,2,'OFF'),
('2026-01',31,3,'A'),
('2026-01',31,4,'C'),
('2026-01',31,5,'OFF'),
('2026-01',31,6,'OFF'),
('2026-02',1,1,'OFF'),
('2026-02',1,2,'A'),
('2026-02',1,3,'A'),
('2026-02',1,4,'C'),
('2026-02',1,5,'OFF'),
('2026-02',1,6,'OFF'),
('2026-02',2,1,'OFF'),
('2026-02',2,2,'OFF'),
('2026-02',2,3,'OFF'),
('2026-02',2,4,'A'),
('2026-02',2,5,'C'),
('2026-02',2,6,'B'),
('2026-02',3,1,'OFF'),
('2026-02',3,2,'OFF');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-02',3,3,'OFF'),
('2026-02',3,4,'OFF'),
('2026-02',3,5,'C'),
('2026-02',3,6,'OFF'),
('2026-02',4,1,'B'),
('2026-02',4,2,'B'),
('2026-02',4,3,'B'),
('2026-02',4,4,'C'),
('2026-02',4,5,'OFF'),
('2026-02',4,6,'OFF'),
('2026-02',5,1,'B'),
('2026-02',5,2,'B'),
('2026-02',5,3,'OFF'),
('2026-02',5,4,'OFF'),
('2026-02',5,5,'C'),
('2026-02',5,6,'B'),
('2026-02',6,1,'B'),
('2026-02',6,2,'B'),
('2026-02',6,3,'OFF'),
('2026-02',6,4,'OFF'),
('2026-02',6,5,'C'),
('2026-02',6,6,'B'),
('2026-02',7,1,'OFF'),
('2026-02',7,2,'OFF'),
('2026-02',7,3,'OFF'),
('2026-02',7,4,'OFF'),
('2026-02',7,5,'C'),
('2026-02',7,6,'OFF'),
('2026-02',8,1,'OFF'),
('2026-02',8,2,'OFF'),
('2026-02',8,3,'OFF'),
('2026-02',8,4,'OFF'),
('2026-02',8,5,'C'),
('2026-02',8,6,'OFF'),
('2026-02',9,1,'OFF'),
('2026-02',9,2,'B'),
('2026-02',9,3,'OFF'),
('2026-02',9,4,'OFF'),
('2026-02',9,5,'C'),
('2026-02',9,6,'B'),
('2026-02',10,1,'OFF'),
('2026-02',10,2,'OFF'),
('2026-02',10,3,'B'),
('2026-02',10,4,'C'),
('2026-02',10,5,'OFF'),
('2026-02',10,6,'OFF'),
('2026-02',11,1,'OFF'),
('2026-02',11,2,'OFF'),
('2026-02',11,3,'B'),
('2026-02',11,4,'OFF');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-02',11,5,'C'),
('2026-02',11,6,'B'),
('2026-02',12,1,'B'),
('2026-02',12,2,'B'),
('2026-02',12,3,'B'),
('2026-02',12,4,'OFF'),
('2026-02',12,5,'C'),
('2026-02',12,6,'B'),
('2026-02',13,1,'B'),
('2026-02',13,2,'B'),
('2026-02',13,3,'B'),
('2026-02',13,4,'OFF'),
('2026-02',13,5,'C'),
('2026-02',13,6,'B'),
('2026-02',14,1,'OFF'),
('2026-02',14,2,'OFF'),
('2026-02',14,3,'OFF'),
('2026-02',14,4,'C'),
('2026-02',14,5,'OFF'),
('2026-02',14,6,'OFF'),
('2026-02',15,1,'OFF'),
('2026-02',15,2,'OFF'),
('2026-02',15,3,'OFF'),
('2026-02',15,4,'C'),
('2026-02',15,5,'OFF'),
('2026-02',15,6,'OFF'),
('2026-02',16,1,'OFF'),
('2026-02',16,2,'OFF'),
('2026-02',16,3,'OFF'),
('2026-02',16,4,'C'),
('2026-02',16,5,'OFF'),
('2026-02',16,6,'OFF'),
('2026-02',17,1,'OFF'),
('2026-02',17,2,'OFF'),
('2026-02',17,3,'OFF'),
('2026-02',17,4,'OFF'),
('2026-02',17,5,'OFF'),
('2026-02',17,6,'OFF'),
('2026-02',18,1,'OFF'),
('2026-02',18,2,'OFF'),
('2026-02',18,3,'OFF'),
('2026-02',18,4,'OFF'),
('2026-02',18,5,'OFF'),
('2026-02',18,6,'OFF'),
('2026-02',19,1,'OFF'),
('2026-02',19,2,'OFF'),
('2026-02',19,3,'OFF'),
('2026-02',19,4,'OFF'),
('2026-02',19,5,'C'),
('2026-02',19,6,'OFF');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-02',20,1,'B'),
('2026-02',20,2,'B'),
('2026-02',20,3,'B'),
('2026-02',20,4,'C'),
('2026-02',20,5,'OFF'),
('2026-02',20,6,'B'),
('2026-02',21,1,'B'),
('2026-02',21,2,'B'),
('2026-02',21,3,'B'),
('2026-02',21,4,'C'),
('2026-02',21,5,'OFF'),
('2026-02',21,6,'B'),
('2026-02',22,1,'OFF'),
('2026-02',22,2,'OFF'),
('2026-02',22,3,'OFF'),
('2026-02',22,4,'C'),
('2026-02',22,5,'OFF'),
('2026-02',22,6,'OFF'),
('2026-02',23,1,'OFF'),
('2026-02',23,2,'OFF'),
('2026-02',23,3,'OFF'),
('2026-02',23,4,'C'),
('2026-02',23,5,'OFF'),
('2026-02',23,6,'OFF'),
('2026-02',24,1,'OFF'),
('2026-02',24,2,'B'),
('2026-02',24,3,'B'),
('2026-02',24,4,'OFF'),
('2026-02',24,5,'C'),
('2026-02',24,6,'B'),
('2026-02',25,1,'B'),
('2026-02',25,2,'OFF'),
('2026-02',25,3,'B'),
('2026-02',25,4,'OFF'),
('2026-02',25,5,'C'),
('2026-02',25,6,'OFF'),
('2026-02',26,1,'B'),
('2026-02',26,2,'B'),
('2026-02',26,3,'B'),
('2026-02',26,4,'OFF'),
('2026-02',26,5,'C'),
('2026-02',26,6,'B'),
('2026-02',27,1,'B'),
('2026-02',27,2,'B'),
('2026-02',27,3,'B'),
('2026-02',27,4,'OFF'),
('2026-02',27,5,'C'),
('2026-02',27,6,'B'),
('2026-02',28,1,'B'),
('2026-02',28,2,'B');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-02',28,3,'B'),
('2026-02',28,4,'C'),
('2026-02',28,5,'OFF'),
('2026-02',28,6,'B'),
('2026-03',1,1,'OFF'),
('2026-03',1,2,'OFF'),
('2026-03',1,3,'OFF'),
('2026-03',1,4,'C'),
('2026-03',1,5,'OFF'),
('2026-03',1,6,'OFF'),
('2026-03',2,1,'OFF'),
('2026-03',2,2,'OFF'),
('2026-03',2,3,'OFF'),
('2026-03',2,4,'C'),
('2026-03',2,5,'OFF'),
('2026-03',2,6,'OFF'),
('2026-03',3,1,'B'),
('2026-03',3,2,'B'),
('2026-03',3,3,'B'),
('2026-03',3,4,'OFF'),
('2026-03',3,5,'C'),
('2026-03',3,6,'B'),
('2026-03',4,1,'B'),
('2026-03',4,2,'B'),
('2026-03',4,3,'B'),
('2026-03',4,4,'OFF'),
('2026-03',4,5,'C'),
('2026-03',4,6,'B'),
('2026-03',5,1,'B'),
('2026-03',5,2,'B'),
('2026-03',5,3,'B'),
('2026-03',5,4,'C'),
('2026-03',5,5,'C'),
('2026-03',5,6,'B'),
('2026-03',6,1,'B'),
('2026-03',6,2,'B'),
('2026-03',6,3,'B'),
('2026-03',6,4,'C'),
('2026-03',6,5,'C'),
('2026-03',6,6,'B'),
('2026-03',7,1,'OFF'),
('2026-03',7,2,'OFF'),
('2026-03',7,3,'OFF'),
('2026-03',7,4,'C'),
('2026-03',7,5,'OFF'),
('2026-03',7,6,'OFF'),
('2026-03',8,1,'OFF'),
('2026-03',8,2,'OFF'),
('2026-03',8,3,'OFF'),
('2026-03',8,4,'C');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-03',8,5,'OFF'),
('2026-03',8,6,'OFF'),
('2026-03',9,1,'B'),
('2026-03',9,2,'B'),
('2026-03',9,3,'연차'),
('2026-03',9,4,'OFF'),
('2026-03',9,5,'C'),
('2026-03',9,6,'B'),
('2026-03',10,1,'B'),
('2026-03',10,2,'B'),
('2026-03',10,3,'연차'),
('2026-03',10,4,'OFF'),
('2026-03',10,5,'C'),
('2026-03',10,6,'B'),
('2026-03',11,1,'B'),
('2026-03',11,2,'B'),
('2026-03',11,3,'B'),
('2026-03',11,4,'OFF'),
('2026-03',11,5,'C'),
('2026-03',11,6,'B'),
('2026-03',12,1,'B'),
('2026-03',12,2,'B'),
('2026-03',12,3,'B'),
('2026-03',12,4,'C'),
('2026-03',12,5,'C'),
('2026-03',12,6,'B'),
('2026-03',13,1,'B'),
('2026-03',13,2,'B'),
('2026-03',13,3,'B'),
('2026-03',13,4,'C'),
('2026-03',13,5,'연차'),
('2026-03',13,6,'B'),
('2026-03',14,1,'OFF'),
('2026-03',14,2,'OFF'),
('2026-03',14,3,'OFF'),
('2026-03',14,4,'C'),
('2026-03',14,5,'OFF'),
('2026-03',14,6,'OFF'),
('2026-03',15,1,'OFF'),
('2026-03',15,2,'OFF'),
('2026-03',15,3,'OFF'),
('2026-03',15,4,'C'),
('2026-03',15,5,'OFF'),
('2026-03',15,6,'OFF'),
('2026-03',16,1,'B'),
('2026-03',16,2,'B'),
('2026-03',16,3,'B'),
('2026-03',16,4,'OFF'),
('2026-03',16,5,'C'),
('2026-03',16,6,'B');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-03',17,1,'B'),
('2026-03',17,2,'B'),
('2026-03',17,3,'B'),
('2026-03',17,4,'OFF'),
('2026-03',17,5,'C'),
('2026-03',17,6,'B'),
('2026-03',18,1,'B'),
('2026-03',18,2,'B'),
('2026-03',18,3,'B'),
('2026-03',18,4,'C'),
('2026-03',18,5,'C'),
('2026-03',18,6,'B'),
('2026-03',19,1,'B'),
('2026-03',19,2,'B'),
('2026-03',19,3,'B'),
('2026-03',19,4,'C'),
('2026-03',19,5,'C'),
('2026-03',19,6,'B'),
('2026-03',20,1,'B'),
('2026-03',20,2,'B'),
('2026-03',20,3,'B'),
('2026-03',20,4,'C'),
('2026-03',20,5,'C'),
('2026-03',20,6,'B'),
('2026-03',21,1,'OFF'),
('2026-03',21,2,'OFF'),
('2026-03',21,3,'OFF'),
('2026-03',21,4,'C'),
('2026-03',21,5,'OFF'),
('2026-03',21,6,'OFF'),
('2026-03',22,1,'OFF'),
('2026-03',22,2,'OFF'),
('2026-03',22,3,'OFF'),
('2026-03',22,4,'C'),
('2026-03',22,5,'OFF'),
('2026-03',22,6,'OFF'),
('2026-03',23,1,'B'),
('2026-03',23,2,'B'),
('2026-03',23,3,'B'),
('2026-03',23,4,'OFF'),
('2026-03',23,5,'C'),
('2026-03',23,6,'B'),
('2026-03',24,1,'B'),
('2026-03',24,2,'B'),
('2026-03',24,3,'B'),
('2026-03',24,4,'OFF'),
('2026-03',24,5,'C'),
('2026-03',24,6,'B'),
('2026-03',25,1,'B'),
('2026-03',25,2,'B');
INSERT INTO schedules (month_key,day,employee_id,site_code) VALUES
('2026-03',25,3,'B'),
('2026-03',25,4,'C'),
('2026-03',25,5,'C'),
('2026-03',25,6,'B'),
('2026-03',26,1,'B'),
('2026-03',26,2,'B'),
('2026-03',26,3,'B'),
('2026-03',26,4,'C'),
('2026-03',26,5,'C'),
('2026-03',26,6,'B'),
('2026-03',27,1,'연차'),
('2026-03',27,2,'B'),
('2026-03',27,3,'B'),
('2026-03',27,4,'C'),
('2026-03',27,5,'C'),
('2026-03',27,6,'B'),
('2026-03',28,1,'OFF'),
('2026-03',28,2,'OFF'),
('2026-03',28,3,'OFF'),
('2026-03',28,4,'C'),
('2026-03',28,5,'C'),
('2026-03',28,6,'OFF'),
('2026-03',29,1,'OFF'),
('2026-03',29,2,'OFF'),
('2026-03',29,3,'OFF'),
('2026-03',29,4,'OFF'),
('2026-03',29,5,'OFF'),
('2026-03',29,6,'OFF'),
('2026-03',30,1,'B'),
('2026-03',30,2,'B'),
('2026-03',30,3,'B'),
('2026-03',30,4,'C'),
('2026-03',30,5,'C'),
('2026-03',30,6,'B'),
('2026-03',31,1,'B'),
('2026-03',31,2,'B'),
('2026-03',31,3,'B'),
('2026-03',31,4,'OFF'),
('2026-03',31,5,'C'),
('2026-03',31,6,'B');