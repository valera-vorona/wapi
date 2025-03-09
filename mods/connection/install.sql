create schema if not exists connection;

insert into core.apis(name, schema, auth_required) values ('connection', 'connection', false);

insert into core.roles_functions (role_id, schema_name, function_name) values (
  (select id from core.roles where name='user'),
  'api',
  'post_logout'
);

--drop table connection.passwds;
create table if not exists connection.passwds (
  user_id bigint references core.users(id) primary key not null,
  passwd text,
  activation_key text unique,
  deleted boolean not null default false
);
