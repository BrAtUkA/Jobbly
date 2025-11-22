-- Function to handle new user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  user_type text;
  user_name text;
  user_desc text;
  user_contact text;
  user_edu text;
begin
  -- Extract metadata
  user_type := new.raw_user_meta_data->>'user_type';
  user_name := new.raw_user_meta_data->>'name';
  
  if user_type = 'company' then
    user_desc := new.raw_user_meta_data->>'description';
    user_contact := new.raw_user_meta_data->>'contact_no';
    
    insert into public.companies (
      "companyId", 
      "email", 
      "companyName", 
      "description", 
      "contactNo", 
      "createdAt"
    )
    values (
      new.id, 
      new.email, 
      coalesce(user_name, 'New Company'), 
      coalesce(user_desc, ''), 
      coalesce(user_contact, ''), 
      now()
    );
    
  elsif user_type = 'seeker' then
    user_edu := new.raw_user_meta_data->>'education';
    
    insert into public.seekers (
      "seekerId", 
      "email", 
      "fullName", 
      "education", 
      "createdAt"
    )
    values (
      new.id, 
      new.email, 
      coalesce(user_name, 'New User'), 
      coalesce(user_edu, 'matric'), 
      now()
    );
  end if;
  
  return new;
end;
$$;

-- Trigger to call the function on user creation
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
