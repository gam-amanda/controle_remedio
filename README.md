# Controle de Medicamentos

Aplicativo multiplataforma desenvolvido em **Flutter** e **Dart** para controlar os medicamentos de uso diário. Cada usuário cria sua conta, faz login e gerencia a própria lista de remédios (nome, dosagem, horário, datas de início e término e observações). Os dados ficam salvos na nuvem, em uma base **Supabase (PostgreSQL)**.

## Funcionalidades principais

- **Autenticação:** cadastro, login e logout com e-mail e senha.
- **Proteção de telas:** a tela principal só abre para usuários autenticados; sem sessão, o app volta para o login. Quem já está logado abre o app direto na tela principal.
- **CRUD completo de medicamentos:**
  - **Criar:** formulário para cadastrar um novo medicamento.
  - **Ler:** lista com os medicamentos do usuário logado, do mais novo para o mais antigo.
  - **Atualizar:** o botão de editar abre o formulário já preenchido e salva as alterações.
  - **Excluir:** o botão de lixeira remove o medicamento.
- **Validação de formulários:** campos obrigatórios, e-mail válido, senha com no mínimo 6 caracteres, confirmação de senha, horário no formato HH:MM e quantidade maior que zero.
- **Tratamento de erros:** mensagens claras para login inválido, campos vazios, e-mail já cadastrado, senha fraca e falta de conexão.
- **Navegação entre telas:** login, cadastro, tela principal e formulário de medicamento.

## Tecnologias utilizadas

- [Flutter](https://flutter.dev/) e [Dart](https://dart.dev/)
- [Supabase](https://supabase.com/) (Auth + banco PostgreSQL) com o pacote [`supabase_flutter`](https://pub.dev/packages/supabase_flutter)
- Navegação por rotas nomeadas (`Navigator` e `MaterialApp.routes`)

## Estrutura do projeto

```
lib/
├── main.dart                     # Inicialização do Supabase, rotas e rota inicial
├── models/
│   └── remedio.dart              # Modelo Remedio (fromMap / toMap)
├── services/
│   ├── auth_service.dart         # Login, cadastro, logout e tradução dos erros
│   └── database_service.dart     # CRUD da tabela 'remedios'
├── screens/
│   ├── login_screen.dart
│   ├── registro_screen.dart
│   ├── home_screen.dart          # Lista de medicamentos (Read / Delete)
│   └── remedio_form_screen.dart  # Formulário (Create / Update)
└── widgets/
    ├── campo_texto.dart          # Campo de texto padrão com validação
    └── rota_protegida.dart       # Bloqueia telas para usuários não autenticados
test/
└── remedio_test.dart             # Testes do modelo Remedio
```

As telas cuidam apenas da interface. Toda a comunicação com o Supabase fica nos serviços, e o modelo converte os dados entre o app e o banco.

## Como executar o projeto

**Pré-requisitos:** [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (a versão do Dart exigida está em `pubspec.yaml`) e um dispositivo, emulador ou navegador para rodar o app.

1. Clone o repositório e entre na pasta do projeto:
   ```bash
   git clone <url-do-repositorio>
   cd agam_control_rem_flutter_application
   ```
2. Baixe as dependências:
   ```bash
   flutter pub get
   ```
3. Execute o app:
   ```bash
   flutter run              # dispositivo ou emulador conectado
   flutter run -d chrome    # navegador
   ```
4. (Opcional) Rode os testes:
   ```bash
   flutter test
   ```

### Usando o seu próprio projeto Supabase

O app já vem apontando para um projeto Supabase em `lib/main.dart`. Para usar o seu próprio:

1. Crie um projeto em [supabase.com](https://supabase.com/).
2. Em **Project Settings → API**, copie a **Project URL** e a chave pública (**anon / publishable key**) e coloque em `Supabase.initialize(...)`, no `lib/main.dart`.
3. No **SQL Editor**, crie a tabela e as regras de segurança:

```sql
create table public.remedios (
  id bigint generated always as identity primary key,
  usuario_id uuid not null references auth.users (id) on delete cascade,
  nome text not null,
  dosagem text not null,
  horarios text[] not null,
  data_inicio date not null,
  data_fim date,
  tipo_repeticao text,        -- 'Não se repete', 'Uso contínuo' ou 'Cada X horas'
  intervalo_horas numeric,    -- usado quando o tipo é 'Cada X horas'
  observacoes text not null default '',
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  check (cardinality(horarios) > 0),
  check (data_fim is null or data_fim >= data_inicio)
);

-- Cada usuário enxerga e altera somente os próprios registros
alter table public.remedios enable row level security;

create policy "usuario ve os proprios remedios"
  on public.remedios for select to authenticated
  using (auth.uid() = usuario_id);

create policy "usuario cria os proprios remedios"
  on public.remedios for insert to authenticated
  with check (auth.uid() = usuario_id);

create policy "usuario edita os proprios remedios"
  on public.remedios for update to authenticated
  using (auth.uid() = usuario_id)
  with check (auth.uid() = usuario_id);

create policy "usuario exclui os proprios remedios"
  on public.remedios for delete to authenticated
  using (auth.uid() = usuario_id);
```

Se a tabela `remedios` já existia sem as colunas `tipo_repeticao` e `intervalo_horas`, basta adicioná-las:

```sql
alter table public.remedios
  add column if not exists tipo_repeticao text,
  add column if not exists intervalo_horas numeric;
```

Se a opção **Confirm email** estiver ativa em **Authentication → Providers → Email**, o usuário precisa confirmar o e-mail antes do primeiro login. O app já trata esse caso e avisa na tela de cadastro.

## Autenticação

A autenticação usa o **Supabase Auth** com e-mail e senha, centralizada em `AuthService`:

- No **cadastro**, o nome do usuário é gravado nos metadados da conta (`userMetadata['nome']`) e usado na saudação "Olá, ..." da tela principal.
- No **login**, o Supabase devolve uma sessão que fica salva no dispositivo. Por isso, ao reabrir o app, o usuário continua logado.
- No **logout**, a sessão é encerrada e o app volta para o login.
- A tela principal é envolvida pelo widget `RotaProtegida`, que redireciona para o login quando não há sessão ativa.

## Base de dados

Os dados ficam na tabela `remedios` do Supabase (PostgreSQL), acessada pelo `DatabaseService`. Cada registro guarda o `usuario_id` do dono, e as políticas de **Row Level Security (RLS)** garantem que um usuário nunca veja nem altere os medicamentos de outro. As operações do CRUD são `select`, `insert`, `update` e `delete` filtrados pelo usuário logado.

## Limitações conhecidas

- Apenas o horário inicial é salvo; os demais horários do dia (calculados a partir do intervalo em horas) não são gerados.
- Medicamentos cadastrados antes das colunas `tipo_repeticao` e `intervalo_horas` não têm esses valores; ao editá-los, o tipo de repetição é deduzido pelas datas.
- Não há notificações de lembrete de horário.