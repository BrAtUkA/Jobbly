-- =====================================================
-- JOBBLY DATABASE SETUP
-- 
-- Run this entire file in your Supabase SQL Editor
-- to set up the complete database schema.
-- =====================================================


-- =====================================================
-- 1. EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- =====================================================
-- 2. TABLES
-- =====================================================

-- Companies (linked to auth.users)
CREATE TABLE public.companies (
  "companyId" uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  "companyName" text NOT NULL,
  "description" text,
  "logoUrl" text,
  "website" text,
  "contactNo" text,
  "email" text,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Seekers (linked to auth.users)
CREATE TABLE public.seekers (
  "seekerId" uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  "fullName" text NOT NULL,
  "pfp" text,
  "resumeUrl" text,
  "experience" text,
  "education" text,
  "phone" text,
  "location" text,
  "email" text,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Jobs
CREATE TABLE public.jobs (
  "jobId" uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  "companyId" uuid REFERENCES public.companies("companyId") ON DELETE CASCADE NOT NULL,
  "title" text NOT NULL,
  "description" text NOT NULL,
  "location" text NOT NULL,
  "minSalary" numeric,
  "maxSalary" numeric,
  "jobType" text NOT NULL,
  "requiredEducation" text NOT NULL,
  "postedDate" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "status" text NOT NULL
);

-- Skills
CREATE TABLE public.skills (
  "skillId" uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  "skillName" text NOT NULL,
  "category" text NOT NULL
);

-- Quizzes
CREATE TABLE public.quizzes (
  "quizId" uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  "jobId" uuid REFERENCES public.jobs("jobId") ON DELETE CASCADE NOT NULL,
  "companyId" uuid REFERENCES public.companies("companyId") ON DELETE CASCADE NOT NULL,
  "title" text NOT NULL,
  "duration" integer NOT NULL,
  "passingScore" integer NOT NULL,
  "createdDate" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Questions
CREATE TABLE public.questions (
  "questionId" uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  "quizId" uuid REFERENCES public.quizzes("quizId") ON DELETE CASCADE NOT NULL,
  "questionText" text NOT NULL,
  "optionA" text NOT NULL,
  "optionB" text NOT NULL,
  "optionC" text NOT NULL,
  "optionD" text NOT NULL,
  "correctAnswer" text NOT NULL
);

-- Quiz Attempts
CREATE TABLE public.quiz_attempts (
  "attemptId" uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  "quizId" uuid REFERENCES public.quizzes("quizId") ON DELETE CASCADE NOT NULL,
  "seekerId" uuid REFERENCES public.seekers("seekerId") ON DELETE CASCADE NOT NULL,
  "score" integer NOT NULL,
  "attemptDate" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "isPassed" boolean NOT NULL,
  "timeTaken" integer NOT NULL
);

-- Applications
CREATE TABLE public.applications (
  "applicationId" uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  "jobId" uuid REFERENCES public.jobs("jobId") ON DELETE CASCADE NOT NULL,
  "seekerId" uuid REFERENCES public.seekers("seekerId") ON DELETE CASCADE NOT NULL,
  "quizAttemptId" uuid REFERENCES public.quiz_attempts("attemptId") ON DELETE SET NULL,
  "appliedDate" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "status" text NOT NULL
);

-- Job Skills (junction table)
CREATE TABLE public.job_skills (
  "jobId" uuid REFERENCES public.jobs("jobId") ON DELETE CASCADE NOT NULL,
  "skillId" uuid REFERENCES public.skills("skillId") ON DELETE CASCADE NOT NULL,
  PRIMARY KEY ("jobId", "skillId")
);

-- Seeker Skills (junction table)
CREATE TABLE public.seeker_skills (
  "seekerId" uuid REFERENCES public.seekers("seekerId") ON DELETE CASCADE NOT NULL,
  "skillId" uuid REFERENCES public.skills("skillId") ON DELETE CASCADE NOT NULL,
  "proficiencyLevel" text NOT NULL,
  PRIMARY KEY ("seekerId", "skillId")
);


-- =====================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seekers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seeker_skills ENABLE ROW LEVEL SECURITY;


-- =====================================================
-- 4. RLS POLICIES - COMPANIES
-- =====================================================

CREATE POLICY "Companies are viewable by everyone" 
  ON public.companies FOR SELECT USING (true);

CREATE POLICY "Users can insert their own company profile" 
  ON public.companies FOR INSERT WITH CHECK (auth.uid() = "companyId");

CREATE POLICY "Users can update their own company profile" 
  ON public.companies FOR UPDATE USING (auth.uid() = "companyId");


-- =====================================================
-- 5. RLS POLICIES - SEEKERS
-- =====================================================

CREATE POLICY "Seekers are viewable by everyone" 
  ON public.seekers FOR SELECT USING (true);

CREATE POLICY "Users can insert their own seeker profile" 
  ON public.seekers FOR INSERT WITH CHECK (auth.uid() = "seekerId");

CREATE POLICY "Users can update their own seeker profile" 
  ON public.seekers FOR UPDATE USING (auth.uid() = "seekerId");


-- =====================================================
-- 6. RLS POLICIES - JOBS
-- =====================================================

CREATE POLICY "Jobs are viewable by everyone" 
  ON public.jobs FOR SELECT USING (true);

CREATE POLICY "Companies can insert jobs" 
  ON public.jobs FOR INSERT 
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.companies 
    WHERE "companyId" = auth.uid() 
    AND "companyId" = public.jobs."companyId"
  ));

CREATE POLICY "Companies can update own jobs" 
  ON public.jobs FOR UPDATE 
  USING (EXISTS (
    SELECT 1 FROM public.companies 
    WHERE "companyId" = auth.uid() 
    AND "companyId" = public.jobs."companyId"
  ));

CREATE POLICY "Companies can delete their own jobs" 
  ON public.jobs FOR DELETE 
  USING (EXISTS (
    SELECT 1 FROM public.companies 
    WHERE "companyId" = auth.uid() 
    AND "companyId" = public.jobs."companyId"
  ));


-- =====================================================
-- 7. RLS POLICIES - SKILLS
-- =====================================================

CREATE POLICY "Authenticated users can view skills" 
  ON public.skills FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert skills" 
  ON public.skills FOR INSERT WITH CHECK (auth.role() = 'authenticated');


-- =====================================================
-- 8. RLS POLICIES - QUIZZES
-- =====================================================

CREATE POLICY "Quizzes are viewable by everyone" 
  ON public.quizzes FOR SELECT USING (true);

CREATE POLICY "Companies can insert their own quizzes" 
  ON public.quizzes FOR INSERT WITH CHECK (auth.uid() = "companyId");

CREATE POLICY "Companies can update their own quizzes" 
  ON public.quizzes FOR UPDATE USING (auth.uid() = "companyId");

CREATE POLICY "Companies can delete their own quizzes" 
  ON public.quizzes FOR DELETE USING (auth.uid() = "companyId");


-- =====================================================
-- 9. RLS POLICIES - QUESTIONS
-- =====================================================

CREATE POLICY "Questions are viewable by everyone" 
  ON public.questions FOR SELECT USING (true);

CREATE POLICY "Companies can insert questions for their quizzes" 
  ON public.questions FOR INSERT 
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.quizzes 
    WHERE "quizId" = public.questions."quizId" 
    AND "companyId" = auth.uid()
  ));

CREATE POLICY "Companies can update questions for their quizzes" 
  ON public.questions FOR UPDATE 
  USING (EXISTS (
    SELECT 1 FROM public.quizzes 
    WHERE "quizId" = public.questions."quizId" 
    AND "companyId" = auth.uid()
  ));

CREATE POLICY "Companies can delete questions for their quizzes" 
  ON public.questions FOR DELETE 
  USING (EXISTS (
    SELECT 1 FROM public.quizzes 
    WHERE "quizId" = public.questions."quizId" 
    AND "companyId" = auth.uid()
  ));


-- =====================================================
-- 10. RLS POLICIES - QUIZ ATTEMPTS
-- =====================================================

CREATE POLICY "Seekers can view their own quiz attempts" 
  ON public.quiz_attempts FOR SELECT USING (auth.uid() = "seekerId");

CREATE POLICY "Companies can view quiz attempts for their quizzes" 
  ON public.quiz_attempts FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM public.quizzes 
    WHERE "quizId" = public.quiz_attempts."quizId" 
    AND "companyId" = auth.uid()
  ));

CREATE POLICY "Seekers can insert their own quiz attempts" 
  ON public.quiz_attempts FOR INSERT WITH CHECK (auth.uid() = "seekerId");


-- =====================================================
-- 11. RLS POLICIES - APPLICATIONS
-- =====================================================

CREATE POLICY "Seekers can view own applications" 
  ON public.applications FOR SELECT USING (auth.uid() = "seekerId");

CREATE POLICY "Companies can view applications for their jobs" 
  ON public.applications FOR SELECT 
  USING (EXISTS (
    SELECT 1 FROM public.jobs 
    WHERE "jobId" = public.applications."jobId" 
    AND "companyId" = auth.uid()
  ));

CREATE POLICY "Seekers can insert applications" 
  ON public.applications FOR INSERT WITH CHECK (auth.uid() = "seekerId");

CREATE POLICY "Companies can update applications for their jobs" 
  ON public.applications FOR UPDATE 
  USING (EXISTS (
    SELECT 1 FROM public.jobs 
    WHERE "jobId" = public.applications."jobId" 
    AND "companyId" = auth.uid()
  ));

CREATE POLICY "Seekers can delete their own applications" 
  ON public.applications FOR DELETE USING (auth.uid() = "seekerId");


-- =====================================================
-- 12. RLS POLICIES - JOB SKILLS
-- =====================================================

CREATE POLICY "Job skills are viewable by everyone" 
  ON public.job_skills FOR SELECT USING (true);

CREATE POLICY "Companies can insert job skills for their jobs" 
  ON public.job_skills FOR INSERT 
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.jobs 
    WHERE "jobId" = public.job_skills."jobId" 
    AND "companyId" = auth.uid()
  ));

CREATE POLICY "Companies can delete job skills for their jobs" 
  ON public.job_skills FOR DELETE 
  USING (EXISTS (
    SELECT 1 FROM public.jobs 
    WHERE "jobId" = public.job_skills."jobId" 
    AND "companyId" = auth.uid()
  ));


-- =====================================================
-- 13. RLS POLICIES - SEEKER SKILLS
-- =====================================================

CREATE POLICY "Seeker skills are viewable by everyone" 
  ON public.seeker_skills FOR SELECT USING (true);

CREATE POLICY "Seekers can insert their own skills" 
  ON public.seeker_skills FOR INSERT WITH CHECK (auth.uid() = "seekerId");

CREATE POLICY "Seekers can update their own skills" 
  ON public.seeker_skills FOR UPDATE USING (auth.uid() = "seekerId");

CREATE POLICY "Seekers can delete their own skills" 
  ON public.seeker_skills FOR DELETE USING (auth.uid() = "seekerId");


-- =====================================================
-- 14. TRIGGER - AUTO CREATE USER PROFILE ON SIGNUP
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_type_value text;
BEGIN
  user_type_value := new.raw_user_meta_data->>'user_type';
  
  IF user_type_value = 'company' THEN
    INSERT INTO public.companies ("companyId", "companyName", "description", "contactNo", "email", "createdAt")
    VALUES (
      new.id,
      COALESCE(new.raw_user_meta_data->>'name', 'Company Name'),
      COALESCE(new.raw_user_meta_data->>'description', ''),
      COALESCE(new.raw_user_meta_data->>'contactNo', ''),
      new.email,
      now()
    );
  ELSIF user_type_value = 'seeker' THEN
    INSERT INTO public.seekers ("seekerId", "fullName", "education", "email", "createdAt")
    VALUES (
      new.id,
      COALESCE(new.raw_user_meta_data->>'name', 'Full Name'),
      COALESCE(new.raw_user_meta_data->>'education', 'matric'),
      new.email,
      now()
    );
  END IF;
  
  RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- =====================================================
-- 15. FUNCTION - DELETE USER ACCOUNT
-- =====================================================

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;


-- =====================================================
-- 16. STORAGE POLICIES - AVATARS BUCKET
-- 
-- First, manually create the 'avatars' bucket in Supabase:
-- Dashboard → Storage → New bucket → Name: avatars → Public: ON
-- =====================================================

CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Public avatar access"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'avatars');


-- =====================================================
-- 17. STORAGE POLICIES - RESUMES BUCKET
-- 
-- First, manually create the 'resumes' bucket in Supabase:
-- Dashboard → Storage → New bucket → Name: resumes → Public: ON
-- =====================================================

CREATE POLICY "Seekers can upload own resume"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'resumes' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Seekers can update own resume"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'resumes' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Seekers can delete own resume"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'resumes' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Public resume access"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'resumes');


-- =====================================================
-- SETUP COMPLETE!
-- 
-- Don't forget to manually create these storage buckets:
-- 1. avatars (public)
-- 2. resumes (public)
-- =====================================================
