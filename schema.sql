-- Rode este arquivo uma vez no SQL Editor do Supabase (depois do schema.sql).
-- Cria a tabela com os dados do evento, editável pelo painel admin.

create table public.rsvp_settings (
  id int primary key default 1 check (id = 1),
  title text not null default 'Nome do evento',
  host text not null default '',
  event_date text not null default '',
  place text not null default '',
  note text not null default '',
  whatsapp_message text not null default E'Olá, {nome}! 🎉\n\nVocê está convidado(a) para {evento}.\n📅 {data}\n📍 {local}\n\nConfirme sua presença pelo link:\n{link}',
  updated_at timestamptz not null default now()
);

insert into public.rsvp_settings (id) values (1);

alter table public.rsvp_settings enable row level security;

-- Só o administrador lê e altera a tabela diretamente.
create policy "rsvp settings admin" on public.rsvp_settings for all to authenticated
  using ((auth.jwt() ->> 'email') = 'gantoniomoraes97@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'gantoniomoraes97@gmail.com');

-- A página do convite lê apenas os dados públicos do evento.
create function public.rsvp_get_event()
returns table (title text, host text, event_date text, place text, note text)
language sql security definer set search_path = public as $$
  select s.title, s.host, s.event_date, s.place, s.note
  from public.rsvp_settings s where s.id = 1;
$$;

grant execute on function public.rsvp_get_event() to anon, authenticated;
