-- =====================================================
-- DELETE USER FUNCTION
-- 
-- This function allows users to delete their own account.
-- Run this script in Supabase SQL Editor to enable 
-- account deletion functionality.
-- =====================================================

-- Function to delete user account (user can only delete themselves)
create or replace function public.delete_user_account()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  -- Verify the user is authenticated
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  
  -- Delete from auth.users (this will cascade to companies/seekers and all related data)
  -- Due to ON DELETE CASCADE in foreign keys, all user data will be automatically removed
  delete from auth.users where id = auth.uid();
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function public.delete_user_account() to authenticated;
