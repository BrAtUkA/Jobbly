-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Companies Table
create table public.companies (
  "companyId" uuid references auth.users(id) on delete cascade primary key,
  "companyName" text not null,
  "description" text,
  "logoUrl" text,
  "website" text,
  "contactNo" text,
  "email" text,
  "createdAt" timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Seekers Table
create table public.seekers (
  "seekerId" uuid references auth.users(id) on delete cascade primary key,
  "fullName" text not null,
  "pfp" text,
  "resumeUrl" text,
  "experience" text,
  "education" text, -- Enum stored as text
  "phone" text,
  "location" text,
  "email" text,
  "createdAt" timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Jobs Table
create table public.jobs (
  "jobId" uuid default uuid_generate_v4() primary key,
  "companyId" uuid references public.companies("companyId") on delete cascade not null,
  "title" text not null,
  "description" text not null,
  "location" text not null,
  "minSalary" numeric,
  "maxSalary" numeric,
  "jobType" text not null, -- Enum
  "requiredEducation" text not null, -- Enum
  "postedDate" timestamp with time zone default timezone('utc'::text, now()) not null,
  "status" text not null -- Enum
);

-- 4. Skills Table
create table public.skills (
  "skillId" uuid default uuid_generate_v4() primary key,
  "skillName" text not null,
  "category" text not null -- Enum
);

-- 5. Quizzes Table
create table public.quizzes (
  "quizId" uuid default uuid_generate_v4() primary key,
  "jobId" uuid references public.jobs("jobId") on delete cascade not null,
  "companyId" uuid references public.companies("companyId") on delete cascade not null,
  "title" text not null,
  "duration" integer not null, -- in minutes
  "passingScore" integer not null,
  "createdDate" timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Questions Table
create table public.questions (
  "questionId" uuid default uuid_generate_v4() primary key,
  "quizId" uuid references public.quizzes("quizId") on delete cascade not null,
  "questionText" text not null,
  "optionA" text not null,
  "optionB" text not null,
  "optionC" text not null,
  "optionD" text not null,
  "correctAnswer" text not null
);

-- 7. Quiz Attempts Table
create table public.quiz_attempts (
  "attemptId" uuid default uuid_generate_v4() primary key,
  "quizId" uuid references public.quizzes("quizId") on delete cascade not null,
  "seekerId" uuid references public.seekers("seekerId") on delete cascade not null,
  "score" integer not null,
  "attemptDate" timestamp with time zone default timezone('utc'::text, now()) not null,
  "isPassed" boolean not null,
  "timeTaken" integer not null
);

-- 8. Applications Table
create table public.applications (
  "applicationId" uuid default uuid_generate_v4() primary key,
  "jobId" uuid references public.jobs("jobId") on delete cascade not null,
  "seekerId" uuid references public.seekers("seekerId") on delete cascade not null,
  "quizAttemptId" uuid references public.quiz_attempts("attemptId") on delete set null,
  "appliedDate" timestamp with time zone default timezone('utc'::text, now()) not null,
  "status" text not null -- Enum
);

-- 9. Job Skills Junction Table
create table public.job_skills (
  "jobId" uuid references public.jobs("jobId") on delete cascade not null,
  "skillId" uuid references public.skills("skillId") on delete cascade not null,
  primary key ("jobId", "skillId")
);

-- 10. Seeker Skills Junction Table
create table public.seeker_skills (
  "seekerId" uuid references public.seekers("seekerId") on delete cascade not null,
  "skillId" uuid references public.skills("skillId") on delete cascade not null,
  "proficiencyLevel" text not null, -- Enum
  primary key ("seekerId", "skillId")
);

-- Enable Row Level Security (RLS)
alter table public.companies enable row level security;
alter table public.seekers enable row level security;
alter table public.jobs enable row level security;
alter table public.skills enable row level security;
alter table public.quizzes enable row level security;
alter table public.questions enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.applications enable row level security;
alter table public.job_skills enable row level security;
alter table public.seeker_skills enable row level security;

-- RLS Policies

-- Companies:
-- Public read access
create policy "Companies are viewable by everyone" on public.companies for select using (true);
-- Insert/Update only by owner
create policy "Users can insert their own company profile" on public.companies for insert with check (auth.uid() = "companyId");
create policy "Users can update their own company profile" on public.companies for update using (auth.uid() = "companyId");

-- Seekers:
-- Public read access (or restricted to companies? For now public)
create policy "Seekers are viewable by everyone" on public.seekers for select using (true);
-- Insert/Update only by owner
create policy "Users can insert their own seeker profile" on public.seekers for insert with check (auth.uid() = "seekerId");
create policy "Users can update their own seeker profile" on public.seekers for update using (auth.uid() = "seekerId");

-- Jobs:
-- Public read access
create policy "Jobs are viewable by everyone" on public.jobs for select using (true);
-- Insert/Update only by company owner
create policy "Companies can insert jobs" on public.jobs for insert with check (exists (select 1 from public.companies where "companyId" = auth.uid() and "companyId" = public.jobs."companyId"));
create policy "Companies can update own jobs" on public.jobs for update using (exists (select 1 from public.companies where "companyId" = auth.uid() and "companyId" = public.jobs."companyId"));

-- Applications:
-- Seekers can see their own applications
create policy "Seekers can view own applications" on public.applications for select using (auth.uid() = "seekerId");
-- Companies can see applications for their jobs
create policy "Companies can view applications for their jobs" on public.applications for select using (exists (select 1 from public.jobs where "jobId" = public.applications."jobId" and "companyId" = auth.uid()));
-- Seekers can insert applications
create policy "Seekers can insert applications" on public.applications for insert with check (auth.uid() = "seekerId");

-- Other tables (simplified for now - allow authenticated read/write or refine as needed)
create policy "Authenticated users can view skills" on public.skills for select using (auth.role() = 'authenticated');
create policy "Authenticated users can insert skills" on public.skills for insert with check (auth.role() = 'authenticated');

-- Quizzes/Questions/Attempts policies would follow similar logic (Company owns Quiz, Seeker owns Attempt)
