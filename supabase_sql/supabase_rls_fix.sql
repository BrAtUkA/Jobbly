-- =====================================================
-- FIX: Add missing RLS policies for quizzes, questions, 
-- quiz_attempts, job_skills, seeker_skills
-- 
-- Run this script in Supabase SQL Editor to fix the 
-- "row-level security policy violation" error
-- =====================================================

-- QUIZZES: Companies can manage their own quizzes
CREATE POLICY "Quizzes are viewable by everyone" 
  ON public.quizzes FOR SELECT USING (true);

CREATE POLICY "Companies can insert their own quizzes" 
  ON public.quizzes FOR INSERT 
  WITH CHECK (auth.uid() = "companyId");

CREATE POLICY "Companies can update their own quizzes" 
  ON public.quizzes FOR UPDATE 
  USING (auth.uid() = "companyId");

CREATE POLICY "Companies can delete their own quizzes" 
  ON public.quizzes FOR DELETE 
  USING (auth.uid() = "companyId");

-- QUESTIONS: Follow quiz ownership
CREATE POLICY "Questions are viewable by everyone" 
  ON public.questions FOR SELECT USING (true);

CREATE POLICY "Companies can insert questions for their quizzes" 
  ON public.questions FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.quizzes 
      WHERE "quizId" = public.questions."quizId" 
      AND "companyId" = auth.uid()
    )
  );

CREATE POLICY "Companies can update questions for their quizzes" 
  ON public.questions FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.quizzes 
      WHERE "quizId" = public.questions."quizId" 
      AND "companyId" = auth.uid()
    )
  );

CREATE POLICY "Companies can delete questions for their quizzes" 
  ON public.questions FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.quizzes 
      WHERE "quizId" = public.questions."quizId" 
      AND "companyId" = auth.uid()
    )
  );

-- QUIZ_ATTEMPTS: Seekers manage their own attempts, companies can view
CREATE POLICY "Seekers can view their own quiz attempts" 
  ON public.quiz_attempts FOR SELECT 
  USING (auth.uid() = "seekerId");

CREATE POLICY "Companies can view quiz attempts for their quizzes" 
  ON public.quiz_attempts FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.quizzes 
      WHERE "quizId" = public.quiz_attempts."quizId" 
      AND "companyId" = auth.uid()
    )
  );

CREATE POLICY "Seekers can insert their own quiz attempts" 
  ON public.quiz_attempts FOR INSERT 
  WITH CHECK (auth.uid() = "seekerId");

-- JOB_SKILLS: Public read, company insert/delete
CREATE POLICY "Job skills are viewable by everyone" 
  ON public.job_skills FOR SELECT USING (true);

CREATE POLICY "Companies can insert job skills for their jobs" 
  ON public.job_skills FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.jobs 
      WHERE "jobId" = public.job_skills."jobId" 
      AND "companyId" = auth.uid()
    )
  );

CREATE POLICY "Companies can delete job skills for their jobs" 
  ON public.job_skills FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs 
      WHERE "jobId" = public.job_skills."jobId" 
      AND "companyId" = auth.uid()
    )
  );

-- SEEKER_SKILLS: Seekers manage their own
CREATE POLICY "Seeker skills are viewable by everyone" 
  ON public.seeker_skills FOR SELECT USING (true);

CREATE POLICY "Seekers can insert their own skills" 
  ON public.seeker_skills FOR INSERT 
  WITH CHECK (auth.uid() = "seekerId");

CREATE POLICY "Seekers can update their own skills" 
  ON public.seeker_skills FOR UPDATE 
  USING (auth.uid() = "seekerId");

CREATE POLICY "Seekers can delete their own skills" 
  ON public.seeker_skills FOR DELETE 
  USING (auth.uid() = "seekerId");

-- JOBS: Add delete policy (missing from original schema)
CREATE POLICY "Companies can delete their own jobs" 
  ON public.jobs FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.companies 
      WHERE "companyId" = auth.uid() 
      AND "companyId" = public.jobs."companyId"
    )
  );

-- APPLICATIONS: Add update policy for companies (to change status)
CREATE POLICY "Companies can update applications for their jobs" 
  ON public.applications FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs 
      WHERE "jobId" = public.applications."jobId" 
      AND "companyId" = auth.uid()
    )
  );

-- APPLICATIONS: Add delete policy for seekers (to withdraw applications)
CREATE POLICY "Seekers can delete their own applications" 
  ON public.applications FOR DELETE 
  USING (auth.uid() = "seekerId");
