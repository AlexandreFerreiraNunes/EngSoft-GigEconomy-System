# Prompt de Desenvolvimento — Sistema Inteligente de Finanças para Gig Economy

## VISÃO GERAL DO PROJETO

Desenvolva um sistema financeiro completo voltado para profissionais da Gig Economy (motoristas de aplicativo, entregadores, freelancers). O sistema é composto por:

- **Back-end**: API REST em Python (FastAPI)
- **Banco de dados**: MySQL
- **Front-end Web**: React + Vite + Tailwind CSS
- **Mobile**: Flutter
- **Machine Learning**: scikit-learn

Os dois fronts (web e mobile) consomem a mesma API e têm funcionalidades equivalentes, diferindo apenas no layout e nível de detalhe exibido. Existe apenas um tipo de usuário (usuário comum), sem perfil de administrador.

O visual deve ser **minimalista e extremamente intuitivo**, com o mínimo de cliques possível por ação. O público-alvo é de baixa escolaridade digital, então tudo deve ser autoexplicativo, com ícones claros, textos curtos e feedback imediato após cada ação.

---

## AUTENTICAÇÃO E USUÁRIO

### Cadastro
- Campos: nome completo, e-mail, senha, confirmação de senha
- Validação de e-mail único no banco
- Senha armazenada com hash (bcrypt)
- Após cadastro, redirecionar direto para o fluxo de definição de meta mensal

### Login
- Campos: e-mail e senha
- Retorna JWT token (access token)
- Token armazenado no cliente (localStorage no web, SharedPreferences no Flutter)

### Perfil do usuário
- Campos editáveis: nome e foto de perfil
- Foto armazenada como URL (upload para servidor ou base64)
- Endpoint: `PUT /users/me`

### Sem recuperação de senha e sem login social (fora do escopo)

---

## META MENSAL

- O usuário define **uma meta de renda mensal em reais**
- A meta fica salva e permanece ativa até o usuário alterá-la manualmente
- Pode ser alterada a qualquer momento na tela de configurações
- A meta é usada em todos os cálculos do sistema

**Cálculo principal:**
```
dias_restantes = dias úteis restantes no mês atual (dias corridos, não descontar fins de semana)
total_ganho_mes = soma de todos os ganhos registrados no mês atual
valor_diario_necessario = (meta - total_ganho_mes) / dias_restantes
```
Se a meta já foi batida, exibir mensagem de parabéns e valor_diario_necessario = 0.

---

## CATEGORIAS (FIXAS, DEFINIDAS PELO SISTEMA)

### Categorias de Ganhos
- Uber
- 99
- iFood
- Rappi
- Loggi
- Freelance
- Outros

### Categorias de Gastos
- Combustível
- Alimentação
- Manutenção do veículo
- Aluguel / Moradia
- Saúde
- Outros

As categorias são fixas e não podem ser criadas ou editadas pelo usuário.

---

## LANÇAMENTOS (GANHOS E GASTOS)

### Registro de Ganho
- Campos: valor (decimal), categoria (seleção da lista), observação opcional
- Horário capturado automaticamente pelo servidor no momento do POST
- Endpoint: `POST /transactions` com `type: "income"`

### Registro de Gasto
- Campos: valor (decimal), categoria (seleção da lista), observação opcional
- Horário capturado automaticamente pelo servidor
- Endpoint: `POST /transactions` com `type: "expense"`

### Editar Lançamento
- Permite editar valor, categoria e observação
- Não permite editar data/horário
- Endpoint: `PUT /transactions/{id}`

### Excluir Lançamento
- Confirmação antes de excluir ("Tem certeza que deseja excluir este lançamento?")
- Endpoint: `DELETE /transactions/{id}`

### Listagem / Histórico
- Endpoint: `GET /transactions`
- Filtros disponíveis: período (data início / data fim) e categoria
- Ordenação: mais recente primeiro
- Paginação: 20 itens por página

---

## DASHBOARD MOBILE

O dashboard mobile deve ser **extremamente resumido e focado na ação**. Exibir:

1. **Indicador visual de progresso da meta** — barra de progresso ou círculo (estilo gauge) com cor dinâmica:
   - Vermelho: menos de 50% da meta atingida
   - Amarelo: entre 50% e 85%
   - Verde: acima de 85%
2. **Valor que precisa ganhar hoje** para bater a meta (destaque principal, fonte grande)
3. **Botão grande "Registrar Ganho"** — ação principal da tela
4. **Botão secundário "Registrar Gasto"**

Nada mais. Simples, direto, uma leitura de 2 segundos.

---

## DASHBOARD WEB

O dashboard web exibe um panorama completo do mês. Componentes:

1. **Card: Meta do mês vs. total ganho até agora**
   - Meta: R$ X.XXX,XX
   - Ganho até agora: R$ X.XXX,XX
   - Percentual atingido

2. **Card: Valor necessário por dia para bater a meta**
   - Mesmo cálculo descrito acima

3. **Card: Saldo do mês**
   - Saldo = total de ganhos - total de gastos do mês atual

4. **Gráfico de barras: Ganhos dos últimos 30 dias**
   - Eixo X: dias, Eixo Y: valor em reais

5. **Gráfico de rosca (donut): Gastos por categoria no mês atual**
   - Cada fatia = uma categoria com valor e percentual

6. **Card: Previsão de fechamento do mês (IA)**
   - Exibir valor previsto de ganho ao final do mês
   - Exibir se vai bater ou não a meta (com base na previsão)

7. **Tabela: Últimos 10 lançamentos**
   - Colunas: data/hora, tipo (ganho/gasto), categoria, valor
   - Link para ver histórico completo

---

## TELAS DO APP MOBILE

### 1. Splash / Onboarding
- Logo + nome do app
- Botões: "Entrar" e "Cadastrar"

### 2. Cadastro
- Formulário simples: nome, e-mail, senha, confirmar senha
- Após cadastro: tela de definição da meta

### 3. Login
- E-mail e senha
- Botão "Entrar"

### 4. Definição da Meta (primeiro acesso ou alteração)
- Campo numérico: "Qual é sua meta de renda mensal? R$"
- Botão confirmar

### 5. Dashboard (Home)
- Conforme descrito na seção Dashboard Mobile

### 6. Registrar Ganho
- Campo de valor (teclado numérico)
- Seleção de categoria (lista ou chips horizontais)
- Campo de observação (opcional)
- Botão "Salvar"
- Feedback de sucesso após salvar ("Ganho registrado!")

### 7. Registrar Gasto
- Mesma estrutura do registro de ganho

### 8. Histórico
- Lista de lançamentos com filtro por período e categoria
- Cada item: ícone do tipo, categoria, valor, data/hora
- Toque no item: abre modal para editar ou excluir

### 9. Relatórios
- Gráfico de ganhos por dia (últimos 30 dias)
- Gráfico de gastos por categoria (mês atual)
- Comparativo entre meses: gráfico de barras mostrando total ganho por mês nos últimos 6 meses
- Comparativo entre meses: gráfico de barras mostrando total gasto por mês nos últimos 6 meses

### 10. Sugestões da IA
- Cards com insights gerados pelo modelo:
  - Previsão se vai bater a meta
  - Melhor dia da semana para trabalhar (baseado no histórico)
  - Melhor horário do dia para trabalhar (baseado no histórico)
  - Sugestões de comportamento (ex: "Você ganha 40% mais às sextas à noite")
- Atualizado sob demanda (botão "Atualizar sugestões") ou ao entrar na tela

### 11. Configurações
- Alterar meta mensal
- Editar perfil (nome e foto)
- Botão de logout

---

## TELAS DO SITE (WEB)

O site replica todas as funcionalidades do mobile, mas com layout adaptado para tela grande, aproveitando o espaço para exibir mais informações simultaneamente. As telas são:

- Login / Cadastro
- Dashboard (conforme seção Dashboard Web)
- Registrar Ganho / Gasto (modal ou página lateral)
- Histórico com filtros avançados
- Relatórios com gráficos detalhados e comparativo entre meses
- Sugestões da IA
- Configurações (meta e perfil)

---

## MÓDULO DE INTELIGÊNCIA ARTIFICIAL (scikit-learn)

O modelo de ML é treinado com o histórico de transações do próprio usuário. Funcionalidades:

### 1. Previsão de fechamento do mês
- **Modelo**: Regressão Linear (ou regressão com séries temporais simples)
- **Input**: ganhos dos dias anteriores do mês atual
- **Output**: valor previsto total ao final do mês
- **Endpoint**: `GET /ai/forecast`
- Retorna: `{ predicted_total: float, will_reach_goal: bool, confidence: float }`

### 2. Melhor dia da semana para trabalhar
- **Lógica**: agrupar ganhos históricos por dia da semana, calcular média por dia
- **Output**: ranking dos dias da semana por média de ganho
- **Endpoint**: `GET /ai/best-days`

### 3. Melhor horário do dia para trabalhar
- **Lógica**: agrupar ganhos históricos por faixa de horário (manhã 6h-12h, tarde 12h-18h, noite 18h-00h, madrugada 00h-6h), calcular média por faixa
- **Output**: ranking das faixas de horário por média de ganho
- **Endpoint**: `GET /ai/best-hours`

### 4. Sugestões em texto
- Com base nos dados acima, gerar frases curtas e simples para exibir ao usuário
- Exemplos: "Você ganha mais nas sextas-feiras", "Seu período mais lucrativo é à noite", "No ritmo atual, você vai atingir R$ 2.800 este mês"
- Endpoint: `GET /ai/suggestions` — retorna lista de strings

**Observação**: se o usuário tiver menos de 7 dias de histórico, retornar mensagem "Registre mais dias para receber sugestões personalizadas."

---

## ENDPOINTS DA API (resumo)

```
POST   /auth/register
POST   /auth/login

GET    /users/me
PUT    /users/me

GET    /goals/current
POST   /goals
PUT    /goals/{id}

POST   /transactions
GET    /transactions           (query params: type, category, start_date, end_date, page)
PUT    /transactions/{id}
DELETE /transactions/{id}

GET    /dashboard/summary      (retorna todos os dados do dashboard web)
GET    /dashboard/mobile       (retorna dados resumidos para o mobile)

GET    /reports/monthly        (comparativo entre meses, últimos 6)
GET    /reports/by-category    (gastos por categoria no mês)
GET    /reports/daily-income   (ganhos por dia nos últimos 30 dias)

GET    /ai/forecast
GET    /ai/best-days
GET    /ai/best-hours
GET    /ai/suggestions
```

Todos os endpoints (exceto `/auth/*`) requerem JWT no header: `Authorization: Bearer <token>`

---

## BANCO DE DADOS (MySQL)

### Tabela `users`
| Campo | Tipo |
|---|---|
| id | INT PK AUTO_INCREMENT |
| name | VARCHAR(100) |
| email | VARCHAR(150) UNIQUE |
| password_hash | VARCHAR(255) |
| profile_photo_url | VARCHAR(500) NULL |
| created_at | DATETIME |

### Tabela `goals`
| Campo | Tipo |
|---|---|
| id | INT PK AUTO_INCREMENT |
| user_id | INT FK |
| amount | DECIMAL(10,2) |
| created_at | DATETIME |
| is_active | BOOLEAN DEFAULT TRUE |

### Tabela `transactions`
| Campo | Tipo |
|---|---|
| id | INT PK AUTO_INCREMENT |
| user_id | INT FK |
| type | ENUM('income', 'expense') |
| category | VARCHAR(50) |
| amount | DECIMAL(10,2) |
| note | VARCHAR(255) NULL |
| created_at | DATETIME (server-side) |

### Tabela `categories` (opcional, pode ser hardcoded na aplicação)
| Campo | Tipo |
|---|---|
| id | INT PK |
| type | ENUM('income', 'expense') |
| name | VARCHAR(50) |

---

## REGRAS DE NEGÓCIO IMPORTANTES

1. O valor `created_at` de uma transação é sempre definido pelo servidor, nunca pelo cliente.
2. A meta ativa é sempre a mais recente com `is_active = true` para aquele usuário.
3. Ao definir uma nova meta, a anterior recebe `is_active = false`.
4. O cálculo de `valor_diario_necessario` usa dias corridos (incluindo fins de semana), não dias úteis.
5. Se `dias_restantes = 0` (último dia do mês), usar 1 para evitar divisão por zero.
6. Se a meta já foi superada, retornar `valor_diario_necessario = 0` e flag `goal_reached = true`.
7. Um usuário só acessa suas próprias transações e metas (isolamento por `user_id`).
8. O modelo de IA roda no back-end; o front só consome os endpoints `/ai/*`.

---

## OBSERVAÇÕES FINAIS

- Usar variáveis de ambiente para credenciais do banco e secret do JWT (.env)
- CORS configurado para aceitar requisições do front-end web e do app mobile
- Respostas da API sempre em JSON
- Datas e horas em formato ISO 8601 (UTC)
- Valores monetários em DECIMAL, nunca float
- O app mobile (Flutter) e o site (React) consomem exatamente a mesma API
