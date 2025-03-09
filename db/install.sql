create schema if not exists web;
create schema if not exists api;
create schema if not exists core;

create extension if not exists pgcrypto;

-- drop table core.sessions;
-- drop table core.users;

--
--
-- users
--
--

create table if not exists core.users (
  id bigserial primary key not null,
  name text unique not null,
  email text,
  deleted boolean not null default false
);

insert into core.users (name) values ('root');

create table if not exists core.sessions (
  id bigserial primary key not null,
  access_token text unique not null,
  user_id bigint references core.users(id) not null,
  expires_at timestamp -- null means an endless session
);

insert into core.sessions (access_token, user_id) values ('Opti9', 1);

--
--
-- roles
--
--

create table if not exists core.roles (
  id bigserial primary key not null,
  name text unique not null,
  deleted boolean not null default false
);

insert into core.roles(name) values ('admin');

--
--
-- apis 
--
--

create table if not exists core.apis (
  id bigserial primary key not null,
  name text unique not null,
  schema text not null,
  auth_required boolean not null default true,
  deleted boolean not null default false
);

insert into core.apis(name, schema) values ('api', 'api');

--
--
-- functions
--
--

create view core.functions as
  select specific_schema schema, routine_name name
    from information_schema.routines
    where specific_schema='api';
-- TODO: add other specific schemas here

--
--
-- users_roles
--
--

create table if not exists core.users_roles (
  id bigserial primary key not null,
  user_id bigint references core.users(id) not null,
  role_id bigint references core.roles(id) not null,
  deleted boolean not null default false,
  unique(user_id, role_id)
);

insert into core.users_roles (user_id, role_id) values (
  (select id from core.users where name='root'),
  (select id from core.roles where name='admin')
);

--
--
-- roles_functions
--
--

create table if not exists core.roles_functions (
  id bigserial primary key not null,
  role_id bigint references core.roles(id) not null,
  schema_name text not null,
  function_name text not null,
                               -- function_name should present in information_schema.routines as specific_schema, but this is not a table
                               -- I shoild check existence of this function when adding and deleting in core.users.functions and also
                               -- when creating and dropping api functions (in information_schema.routines as specific_schema).
  deleted boolean not null default false,
  unique(role_id, schema_name, function_name)
);

-- adding function to role 'admin'

insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'get_users');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'get_users_details');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'post_users');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'put_users');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'delete_users');

insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'get_roles');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'post_roles');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'delete_roles');

insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'get_functions');

insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'get_roles_functions');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'post_roles_functions');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'delete_roles_functions');

insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'get_users_roles');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'post_users_roles');
insert into core.roles_functions (role_id, schema_name, function_name) values ((select id from core.roles where name='admin'), 'api', 'delete_users_roles');

