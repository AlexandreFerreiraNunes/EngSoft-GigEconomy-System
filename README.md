# EngSoft-GigEconomy-System

Sistema Inteligente de Finanças focado em profissionais da Gig Economy. Utiliza IA para cálculo de metas diárias, previsão de fluxo de caixa e dashboards analíticos para motoristas, entregadores e freelancers.

## Equipe

- Alexandre Ferreira Nunes — Desenvolvedor Front-end Web (React) e Scrum Master
- Bruno Sousa Pereira — Desenvolvedor Back-end e API (Python)
- Enrique Gil Borges — Banco de Dados (MySQL) e Testes
- João Emanuel Zilli dos Santos — Desenvolvedor Mobile (Flutter) e apoio Back-end (Python)

## Stack tecnológica

- Front-end Web: React, Vite e Tailwind CSS
- Mobile: Flutter
- Back-end: Python (Django + DRF)
- Banco de Dados: SQLite (dev) / MySQL (planejado)
- Ferramentas: GitHub, Figma, Postman

## Principais funcionalidades

- Gestão de metas mensais de renda
- Cálculo do valor diário necessário (dias restantes no mês)
- Registro de ganhos e despesas
- Dashboards e resumo do mês

---

# Backend API

## Rodar local

```bash
cd "/home/ghost/Documents/5º Periodo /EngSoft"
source env/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Base URL (dev): `http://127.0.0.1:8000`

> Rotas **sem** barra no final. Ex.: `/auth/login` (não use `/auth/login/`).

## Autenticação (JWT)

- Login retorna `{ "access": "...", "refresh": "..." }`
- Em todo endpoint protegido, envie:

Header:

`Authorization: Bearer <access>`

## Categorias fixas

**Income**: `Uber`, `99`, `iFood`, `Rappi`, `Loggi`, `Freelance`, `Outros`

**Expense**: `Combustível`, `Alimentação`, `Manutenção do veículo`, `Aluguel / Moradia`, `Saúde`, `Outros`

## Endpoints

### Auth

- `POST /auth/register`
- `POST /auth/login`

### Perfil

- `GET /users/me`
- `PUT /users/me`

### Meta

- `GET /goals/current`
- `POST /goals`
- `PUT /goals/{id}`

### Lançamentos

- `POST /transactions`
- `GET /transactions` (paginação e filtros)
  - Query params: `type` (`income|expense`), `category`, `start_date` (`YYYY-MM-DD`), `end_date` (`YYYY-MM-DD`), `page`
- `PUT /transactions/{id}`
- `DELETE /transactions/{id}`

### Dashboards

- `GET /dashboard/mobile`
- `GET /dashboard/summary`

## Exemplos (curl)

### Register

```bash
curl -X POST "http://127.0.0.1:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Joao da Silva",
    "email": "joao@example.com",
    "password": "12345678",
    "password_confirm": "12345678"
  }'
```

### Login (pegar access token)

```bash
curl -X POST "http://127.0.0.1:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@example.com",
    "password": "12345678"
  }'
```

### Criar meta

```bash
curl -X POST "http://127.0.0.1:8000/goals" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access>" \
  -d '{ "amount": "3000.00" }'
```

### Criar lançamento (ganho)

```bash
curl -X POST "http://127.0.0.1:8000/transactions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access>" \
  -d '{
    "type": "income",
    "category": "Uber",
    "amount": "120.50",
    "note": "corridas de manhã"
  }'
```

### Listar lançamentos (filtros)

```bash
curl "http://127.0.0.1:8000/transactions?type=income&category=Uber&page=1" \
  -H "Authorization: Bearer <access>"
```

### Dashboard mobile

```bash
curl "http://127.0.0.1:8000/dashboard/mobile" \
  -H "Authorization: Bearer <access>"
```

## Regras importantes (resumo)

- `created_at` é sempre definido pelo servidor (não editar).
- Meta ativa: ao criar uma meta nova, a anterior vira `is_active=false`.
- Isolamento: usuário só acessa dados dele.

## Troubleshooting

### Erro "No module named 'bcrypt'" no login

Instale as dependências (inclui `bcrypt`):

```bash
pip install -r requirements.txt
```

### `POST /auth/register` retorna 400

Geralmente é payload inválido. Confirme:

- Campos obrigatórios: `name`, `email`, `password`, `password_confirm`
- `password` e `password_confirm` iguais
- Email ainda não cadastrado

Dica: no Insomnia/curl, veja o JSON de erro retornado no body (ele aponta exatamente o campo inválido).

