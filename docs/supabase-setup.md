# Configuracao do Supabase - Lista Facil

## 1. Criar projeto

1. Acesse https://supabase.com/dashboard.
2. Crie um projeto para o Lista Facil.
3. Guarde estas informacoes do projeto:
   - Project URL
   - anon public key

Nao coloque a `service_role key` no app. Ela e secreta e deve ficar somente em ambiente de servidor.

## 2. Criar banco

1. No Supabase, abra `SQL Editor`.
2. Crie uma nova query.
3. Cole todo o conteudo de:

   `supabase/migrations/202607080001_initial_schema.sql`

4. Clique em `Run`.

Esse script cria:

- `profiles`
- `shopping_lists`
- `shopping_items`
- `categories`
- `purchase_history`
- `family_members`
- Row Level Security para cada usuario acessar apenas os proprios dados
- trigger para criar perfil e lista principal automaticamente quando uma conta nasce no Auth

## 3. Configurar login

No painel do Supabase:

1. Abra `Authentication > Providers`.
2. Ative `Email`.
3. Para teste inicial, voce pode desativar confirmacao obrigatoria de email.

## 4. Proximo passo no app

Depois que o projeto estiver criado, informe ao Codex:

- Project URL
- anon public key

Com isso, o app pode trocar o login local por Supabase Auth e sincronizar:

- lista principal
- itens
- categorias
- plano atual
- historico
- membros da familia

## Estrutura de dados principal

`profiles` guarda nome, e-mail, plano e tema.

`shopping_lists` guarda uma ou mais listas por usuario.

`shopping_items` guarda os itens de cada lista, com `done`, `quantity`, `deleted` e `updated_at` para sincronizacao.

`purchase_history` guarda snapshots JSON das compras finalizadas.

`family_members` guarda convites de compartilhamento, ainda preparado para evoluir para colaboracao real.
