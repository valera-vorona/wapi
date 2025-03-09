--
--
-- users
--
--

--drop function api.get_users(bigint, text[], jsonb);
create or replace function api.get_users(bigint, params text[], jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    user_id bigint := params[1];
    rv jsonb;

  begin
    if user_id is not null then
      select jsonb_build_object('id', id, 'name', name, 'email', email) into rv
        from core.users
        where id=user_id and deleted is false;
    else
      select jsonb_agg(jsonb_build_object('id', id, 'name', name, 'email', email)) into rv
        from core.users
        where deleted is false;
    end if;

    if rv is null then
      raise exception '404 Not Found';
    end if;

    return rv;
  end;
$$;

--drop function api.get_users_details(bigint, text[], jsonb);
create or replace function api.get_users_details(bigint, params text[], jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    user_id_ bigint := params[1];
    rv jsonb;

  begin
      select jsonb_build_object(
        'id', id,
        'name', name,
        'email', email,
        'roles', (
            select json_agg(
              json_build_object('name', r.name, 'granted',
                  exists(select 1 from core.users_roles
                  where user_id=user_id_ and role_id=r.id and deleted is false
                )
              )
            ) from core.roles r
            where r.deleted is false
          )
        ) into rv
        from core.users
        where id=user_id_ and deleted is false;

    if rv is null then
      raise exception '404 Not Found';
    end if;

    return rv;
  end;
$$;

--drop function api.post_users(bigint, text[], jsonb);
create or replace function api.post_users(bigint, text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    iid bigint;

  begin
    insert into core.users (name, email)
      values (q->>'name', q->>'email')
      returning id into iid;

    return format('{"iid": %s}', iid);
  exception
    when unique_violation then
      raise exception '403 User name exists';
  end;
$$;

--drop function api.put_users(bigint, text[], jsonb);
create or replace function api.put_users(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    user_id bigint := params[1];
    arg record;

  begin
    if user_id is not null then
      if not exists(select id from core.users where id=user_id and deleted is false) then
	raise exception '404 Not Found';
      end if;
      
      for arg in select * from jsonb_each_text(q) loop
        begin
          execute format('update core.users set %s = $1 where id=$2 and deleted is false', arg.key)
            using arg.value, user_id;
        exception
          when undefined_column then
            raise exception '400 Unknown argument: %', arg.key;

          when datatype_mismatch then
            execute format('update core.users set %s = $1 where id=$2 and deleted is false', arg.key)
            using arg.value::int, user_id;
            --raise exception '400 uuuent: %', arg.key;
        end;
          
      end loop;
    else
      raise exception '400 No user id provided';
    end if;

    return '{"status": "204 No Content"}';
  exception
    when unique_violation then
      raise exception '403 User name exists';
  end;
$$;

--drop function api.delete_users(bigint, text[], jsonb);
create or replace function api.delete_users(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    user_id bigint := params[1];

  begin
    if user_id is not null then
      update core.users set deleted=true where id=user_id and deleted is false returning id into user_id;

      if user_id is null then
	raise exception '404 Not Found';
      end if;
    else
      raise exception '400 No user id provided';
    end if;

    return '{"status": "204 No Content"}';
  end;
$$;

--
--
-- roles 
--
--

--drop function api.get_roles(bigint, text[], jsonb);
create or replace function api.get_roles(bigint, params text[], jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    rv jsonb;

  begin
      select jsonb_agg(name) into rv
        from core.roles
        where deleted is false;

    if rv is null then
      raise exception '404 Not Found';
    end if;

    return rv;
  end;
$$;

--drop function api.get_roles_details(bigint, text[], jsonb);
create or replace function api.get_roles_details(bigint, params text[], jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    role_name text := params[1];
    rv jsonb;

  begin
      select jsonb_build_object(
        'name', r.name,
        'functions', (
            select json_agg(
              json_build_object('name', f.name, 'granted',
                  exists(select 1 from core.roles_functions
                  where role_id=r.id and function_name=f.name and deleted is false
                )
              )
            ) from core.functions f
            where f.schema='api'
          )
        ) into rv
        from core.roles r
        where r.name=role_name and r.deleted is false;

    if rv is null then
      raise exception '404 Not Found';
    end if;

    return rv;
  end;
$$;

--drop function api.post_roles(bigint, text[], jsonb);
create or replace function api.post_roles(bigint, text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  begin
    insert into core.roles (name)
      values (q->>'name');

    return '{"status": "204 No Content"}';
  exception
    when unique_violation then
      raise exception '403 Role exists';
  end;
$$;

--drop function api.idelete_roles(bigint, text[], jsonb);
create or replace function api.delete_roles(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    role_name text := params[1];

  begin
    if role_name is not null then
      update core.roles set deleted=true where name=role_name and deleted is false returning name into role_name;

      if role_name is null then
	raise exception '404 Not Found';
      end if;
    else
      raise exception '400 No role name provided';
    end if;

    return '{"status": "204 No Content"}';
  end;
$$;

--
--
-- functions (for 'api' schema only)
--
--

--drop function api.get_functions(bigint, text[], jsonb);
create or replace function api.get_functions(bigint, params text[], jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    rv jsonb;

  begin
    select jsonb_agg(name) into rv from core.functions where schema='api';

    return rv;
  end;
$$;

--
--
-- roles_functions (for 'api' schema only)
--
--

--drop function api.get_roles_functions(bigint, text[], jsonb);
create or replace function api.get_roles_functions(bigint, params text[], jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    role_name_ text := params[1];
    rv jsonb;

  begin
      select jsonb_agg(rf.function_name) name into rv
        from core.roles_functions rf
        join core.roles r on rf.role_id=r.id
        where rf.deleted is false
          and r.deleted is false
          and r.name=role_name_
          and rf.schema_name='api';

    if rv is null then
      raise exception '404 Not Found';
    end if;

    return rv;
  end;
$$;

--drop function api.post_roles_functions(bigint, text[], jsonb);
create or replace function api.post_roles_functions(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    role_name_ text := params[1];
    function_name_ text := params[2];
    role_id_ bigint;

  begin
    if role_name_ is not null then
      select id from core.roles into role_id_ where name=role_name_;
      if role_id_ is null then
        raise exception '404 Role Not Found';
      end if;
    else
      raise exception '400 No role name provided';
    end if;

    if function_name_ is not null then
      perform 1 from core.functions where name=function_name_;

      if not found then
        raise exception '404 Function Not Found';
      end if;
    else
      raise exception '400 No function name provided';
    end if;

    insert into core.roles_functions (role_id, schema_name, function_name) values (role_id_, 'api', function_name_);

    return '{"status": "204 No Content"}';

  exception
    when unique_violation then
      raise exception '403 Role already has function';
  end;
$$;

--drop function api.delete_roles_functions(bigint, text[], jsonb);
create or replace function api.delete_roles_functions(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    role_name_ text := params[1];
    function_name_ text := params[2];
    role_id_ bigint;

  begin
    if role_name_ is not null then
      select id from core.roles into role_id_ where name=role_name_;
      if role_id_ is null then
        raise exception '404 Role Not Found';
      end if;
    else
      raise exception '400 No role name provided';
    end if;

    if function_name_ is not null then
      perform 1 from core.functions where name=function_name_;

      if not found then
        raise exception '404 Function Not Found';
      end if;
    else
      raise exception '400 No function name provided';
    end if;

    delete from core.roles_functions
      where role_id=role_id
        and schema_name='api'
        and function_name=function_name_;

    if found then
      return '{"status": "204 No Content"}';
    else
      raise exception '403 Role does not have function';
    end if;
    return '{"status": "204 No Content"}';
  end;
$$;

--
--
-- users_roles 
--
--

--drop function api.get_users_roles(bigint, text[], jsonb);
create or replace function api.get_users_roles(bigint, params text[], jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    user_id_ bigint := params[1];
    rv jsonb;

  begin
    if user_id_ is not null then
      select jsonb_agg(r.name) into rv
        from core.users_roles ur
        join core.roles u on ur.user_id=u.id
        join core.roles r on ur.role_id=r.id
	where ur.deleted is false
          and u.deleted is false
          and r.deleted is false
          and ur.user_id=user_id_;

      if rv is null then
        raise exception '404 Not Found';
      end if;

    else
      raise exception '400 No user id provided';
    end if;

    return rv;
  end;
$$;

--drop function api.post_users_roles(bigint, text[], jsonb);
create or replace function api.post_users_roles(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    user_id_ bigint := params[1];
    role_name text := params[2];
    role_id bigint;

  begin
    if user_id_ is not null then
      select id from core.users into user_id_ where id=user_id_;
      if user_id_ is null then
        raise exception '404 User Not Found';
      end if;
    else
      raise exception '400 No user id provided';
    end if;

    if role_name is not null then
      select id from core.roles into role_id where name=role_name;
      if role_id is null then
        raise exception '404 Role Not Found';
      end if;
    else
      raise exception '400 No role name provided';
    end if;

    insert into core.users_roles (user_id, role_id) values (user_id_, role_id);

    return '{"status": "204 No Content"}';

  exception
    when unique_violation then
      raise exception '403 User Role exists';
  end;
$$;

--drop function api.delete_users_roles(bigint, text[], jsonb);
create or replace function api.delete_users_roles(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    user_id_ bigint := params[1];
    role_name text := params[2];
    role_id_ bigint;

  begin
    if user_id_ is not null then
      select id from core.users into user_id_ where id=user_id_;
      if user_id_ is null then
        raise exception '404 User Not Found';
      end if;
    else
      raise exception '400 No user id provided';
    end if;

    if role_name is not null then
      select id from core.roles into role_id_ where name=role_name;
      if role_id_ is null then
        raise exception '404 Role Not Found';
      end if;
    else
      raise exception '400 No role name provided';
    end if;

    delete from core.users_roles
      where user_id=user_id_ and role_id=role_id_;

    if found then
      return '{"status": "204 No Content"}';
    else
      raise exception '403 User Role not exists';
    end if;
  end;
$$;

