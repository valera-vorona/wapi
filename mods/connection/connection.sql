--drop function connection.post_send_iactivation_key(bigint, text[], jsonb);
create or replace function connection.post_gen_activation_key(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    user_id_ bigint = params[1];
    key text := encode(convert_to(web.gen_token(web.random()), 'UTF-8'), 'base64');

  begin
    if user_id_ is null then
      raise exception '404 No User id Provided';
    elsif not exists(select 1 from core.users where id=user_id_ and deleted is false) then
      raise exception '404 User Not Found';
    end if;
      
    update connection.passwds
      set activation_key=key, passwd=null, deleted=false
      where user_id=user_id_;

    if not found then
      insert into connection.passwds (user_id, activation_key) values (user_id_, key);
    end if;

    if not found then
      -- probably user exists but is deleted (connection.passwds.deleted=true)
      raise exception '400 Can''t generate activation key for user';
    end if;

    return '{"status": "204 No Content"}';
  end;
$$;

--drop function connection.activate(bigint, text[], jsonb);
create or replace function connection.post_activate(bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    key_ text := params[1];
    passwd_ text := q->>'password';

  begin
    perform web.check_passwd(passwd_);

    update connection.passwds set activation_key=null, passwd=web.gen_token(passwd_)
      where activation_key=key_;

    if not found then
      raise exception '404 Not Found';
    end if;

    return '{"status": "204 No Content"}';
  end;
$$;

--drop function connection.post_login(bigint, text[], jsonb);
create or replace function connection.post_login(bigint, text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    login_ text := q->>'login';
    passwd_ text := q->>'password';
    user_id_ bigint;
    key_ text;

  begin
    select id into user_id_ from core.users where name=login_ and deleted is false;
    if user_id_ is null then
      raise exception '400 Wrong pair';
    end if;

    if passwd_ is null then
      raise exception '400 Wrong pair';
    end if;

    if not exists(select 1 from connection.passwds
      where user_id=user_id_ and passwd=crypt(passwd_, passwd)) then
      raise exception '400 Wrong pair';
    end if;

    key_ := encode(convert_to(web.gen_token(web.random()), 'UTF-8'), 'base64');

    insert into core.sessions (access_token, user_id, expires_at)
      values (key_, user_id_, now() + interval '12 hours')
      returning access_token into key_;

    if key_ is null then
      raise exception '500 Can''t login';
    end if;

    return jsonb_build_object('access_token', key_);
  end;
$$;

--drop function api.post_logout(bigint, text[], jsonb);
create or replace function api.post_logout(user_id_ bigint, params text[], q jsonb)
  returns jsonb
  language plpgsql
AS $$
  declare
    key_ text := params[1];

  begin
    delete from core.sessions where user_id=user_id_ and access_token=key_;
    if not found then
      raise exception '404 Not Found';
    end if;

    return '{"status": "204 No Content"}';
  end;
$$;

--drop function web.check_passwd(text);
create or replace function web.check_passwd(passwd text)
  returns void
  language plpgsql
AS $$
  begin
    if length(passwd) < 8 then
      raise exception '400 Password should be not less than 8 letters long';
    end if;
  end;
$$;

