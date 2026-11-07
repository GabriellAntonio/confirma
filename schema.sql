-- Funciona em projeto novo ou em um projeto Supabase que você já usa (tudo tem prefixo rsvp_).
-- Cole este arquivo inteiro no SQL Editor do Supabase e clique em "Run".

create table public.rsvp_guests (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  token text not null unique default substr(replace(gen_random_uuid()::text, '-', ''), 1, 12),
  max_companions int not null default 0 check (max_companions >= 0),
  status text not null default 'pending' check (status in ('pending', 'yes', 'no')),
  companions int not null default 0 check (companions >= 0),
  message text,
  responded_at timestamptz,
  created_at timestamptz not null default now()
);

-- Segurança: ninguém lê ou altera a tabela diretamente, exceto você (logado no admin).
alter table public.rsvp_guests enable row level security;
-- IMPORTANTE: troque o e-mail abaixo pelo e-mail do seu usuário administrador (nas 2 linhas).
create policy "rsvp admin total" on public.rsvp_guests for all to authenticated
  using ((auth.jwt() ->> 'email') = 'gantoniomoraes97@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'gantoniomoraes97@gmail.com');

-- Convidado vê apenas o próprio registro, a partir do token do link.
create function public.rsvp_get_guest(p_token text)
returns table (name text, max_companions int, status text, companions int, message text)
language sql security definer set search_path = public as $$
  select g.name, g.max_companions, g.status, g.companions, g.message
  from public.rsvp_guests g where g.token = p_token;
$$;

-- Convidado grava apenas a própria resposta.
create function public.rsvp_submit(p_token text, p_status text, p_companions int, p_message text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if p_status not in ('yes', 'no') then return false; end if;
  update public.rsvp_guests g set
    status = p_status,
    companions = case when p_status = 'yes'
                 then least(greatest(coalesce(p_companions, 0), 0), g.max_companions) else 0 end,
    message = left(p_message, 500),
    responded_at = now()
  where g.token = p_token;
  get diagnostics n = row_count;
  return n > 0;
end;
$$;

grant execute on function public.rsvp_get_guest(text) to anon, authenticated;
grant execute on function public.rsvp_submit(text, text, int, text) to anon, authenticated;
