# TASKS.md

## Resumo e ordem de execução

Esse plano cobre 3 frentes que se conectam: (1) o modal personalizado de permissão no app Flutter, (2) o setup completo da API de notificações em Fastify/TS pronta para deploy no Railway, e (3) a integração do app com essa API — hoje **nenhum gatilho real de notificação existe** (o método `sendPushNotification` em `lib/services/onesignal/oneSignalService.dart` nunca é chamado em lugar nenhum do projeto), então "deixar preciso" nesse plano significa: criar os gatilhos que faltam, mover o disparo para um backend seguro (a REST API key do OneSignal hoje fica embutida no app, exposta no binário) e dar controle granular ao usuário.

**São dois repositórios diferentes:**
- App Flutter: `C:\Users\pedroh.monteiro\dev\me\estudazz` (este repositório, branch `main`) — Features 1 e 3.
- API de notificações: `C:\Users\pedroh.monteiro\dev\sicoob\estudazz-api` (repositório novo e separado, hoje vazio) — Feature 2, com deploy no Railway.

**Caminho crítico:** Feature 2 (API Fastify, no repo `estudazz-api`) bloqueia toda a Feature 3 (integração), que por sua vez bloqueia a Feature 4 (documentação final). A Feature 1 (branch + modal de permissão) é independente e pode ser feita em paralelo com a Feature 2 por qualquer pessoa/sessão.

Isso é mais do que cabe em uma sessão só. Sugestão de corte em fases:
- **Fase A:** Feature 1 (branch + modal, no repo Flutter) + Feature 2 (API, no repo `estudazz-api`) em paralelo.
- **Fase B:** Feature 3 (integração do app com a API já no ar), commitada na mesma branch aberta na task 1.
- **Fase C:** Feature 4 (documentação final, já com o contrato fechado) + abertura do PR da branch do Flutter.

Decisões de arquitetura assumidas a partir das suas respostas:
- A API reage a chamadas do app (agendamento/cancelamento de lembretes, push de sala de estudo, broadcast administrativo) — **exceto** o reengajamento por inatividade, que exige um job periódico do lado do servidor (não tem como o app "avisar" a API de que o usuário sumiu). Como o campo `last_login` já existe em `users` no Firestore (`lib/models/user/userModel.dart`), o job só faz leitura desse campo via Firebase Admin — não precisa de um mecanismo novo de heartbeat.
- Autenticação das rotas de usuário via Firebase ID Token (Firebase Admin SDK no backend). O broadcast administrativo (novidades do app) usa uma chave de admin separada, pois não é uma ação de usuário comum.
- Lembretes de tarefa/evento usam o parâmetro `send_after` do OneSignal para entrega agendada, com o id retornado guardado em um banco Postgres (Prisma) para permitir cancelar/reagendar quando a tarefa/evento muda.

---

## Feature: Branch da feature e modal personalizado de permissão de notificações

### Contexto
Todo o trabalho do lado do Flutter (esse modal + a integração da Feature 3 mais adiante) deve ir para uma branch dedicada, não direto em `main`, para virar um PR único. Hoje `lib/main.dart` chama `OneSignal.Notifications.requestPermission(true)` direto na inicialização do app, disparando o prompt nativo do sistema operacional sem nenhum contexto para o usuário — prática que reduz a taxa de aceitação. A tela dedicada de configurações de notificação (`lib/views/settings/notifications/notificationsPage.dart`) já existe e está registrada nas rotas, mas está vazia e não é acessada de lugar nenhum.

### Tarefas

- [x] 1. Criar a branch da feature para o PR
  - O que fazer: no repositório do Flutter (`C:\Users\pedroh.monteiro\dev\me\estudazz`), a partir de `main` atualizado e com a working tree limpa, criar e mudar para uma branch nova dedicada a essa feature (sugestão de nome: `feat/notificacoes-precisas`). Todas as tarefas das Features "Branch e modal" (2-6) e "Integração do app Flutter" (23-31) devem ser commitadas nela, para no final abrir um único PR contra `main` (task 32 fecha com esse PR).
  - Arquivos: nenhum (ação de git)
  - Pronto quando: `git status` mostra a branch nova como corrente, criada a partir de `main` sem nenhuma alteração pendente.
  - Depende de: nenhuma

- [x] 2. Criar o dialog personalizado de permissão de notificações
  - O que fazer: criar uma classe estática `NotificationPermissionDialog` com o método `showNotificationPermissionDialog({required BuildContext context})`, seguindo o mesmo padrão visual usado em `lib/components/dialog/task/markTaskCompletedDialog.dart` (`AlertDialog` com `backgroundColor: ConstColors.grey900Color`, `borderRadius` de 24, ícone + título centralizados). Conteúdo explicando os benefícios (lembretes de tarefas, eventos e sala de estudo). Duas ações: "Agora não" (`TextButton`, apenas fecha) e "Ativar Notificações" (`ElevatedButton` laranja, chama `OneSignal.Notifications.requestPermission(true)` e fecha). Em ambos os botões, salvar `SharedPreferences` com a chave `hasSeenNotificationPermissionPrompt = true` antes de fechar o dialog.
  - Arquivos: `lib/components/dialog/notifications/notificationPermissionDialog.dart` (novo)
  - Pronto quando: o dialog compila, segue o padrão visual do restante do app, e os dois botões persistem a flag em `SharedPreferences` antes de fechar.
  - Depende de: 1

- [x] 3. Remover a chamada automática de permissão do `main.dart`
  - O que fazer: remover a linha `OneSignal.Notifications.requestPermission(true);` da função `main()`. Manter `OneSignal.Debug.setLogLevel(...)` e `OneSignal.initialize(...)` — só a solicitação de permissão sai daqui.
  - Arquivos: `lib/main.dart` (linha 29)
  - Pronto quando: o app inicializa o SDK do OneSignal normalmente, mas não dispara mais o prompt nativo no cold start.
  - Depende de: 1

- [x] 4. Exibir o modal uma única vez, após o login, na Home
  - O que fazer: em `_HomePageState.initState`, depois de `checkProfileCompletion(...)`, ler `SharedPreferences.getBool('hasSeenNotificationPermissionPrompt')`. Se não estiver marcado e `OneSignal.Notifications.permission` (getter bool) ainda for `false`, usar `WidgetsBinding.instance.addPostFrameCallback` para chamar `NotificationPermissionDialog.showNotificationPermissionDialog(context: context)`.
  - Arquivos: `lib/views/homePage.dart`
  - Pronto quando: em um login novo, o modal aparece uma única vez após a Home renderizar; em aberturas seguintes do app, não reaparece; se a permissão do SO já estiver concedida, o modal é pulado.
  - Depende de: 2, 3

- [x] 5. Reconstruir a página de Configurações de Notificação (hoje vazia)
  - O que fazer: `NotificationsSettingsPage` hoje é um `Scaffold` com `body` vazio. Implementar: (a) um indicador do status atual da permissão (`OneSignal.Notifications.permission`) com botão para reabrir o modal da task 2 caso esteja desativada; (b) switches por categoria de notificação — tarefas, eventos, sala de estudo e novidades do app — persistidos em `SharedPreferences` com as chaves `notif_pref_tasks`, `notif_pref_events`, `notif_pref_studyroom`, `notif_pref_updates` (todas `true` por padrão), seguindo o mesmo padrão de `SwitchListTile` já usado em `_buildNotificationsSwitch` de `lib/views/settings/settingsPage.dart`. Essas preferências serão lidas pela Feature 3 antes de cada chamada à API (tasks 27/28/29/30) para decidir se dispara ou não a notificação daquela categoria.
  - Arquivos: `lib/views/settings/notifications/notificationsPage.dart`
  - Pronto quando: a página mostra o status da permissão e 4 switches funcionais que persistem estado entre aberturas do app.
  - Depende de: 2

- [x] 6. Ligar a página de Configurações de Notificação a partir da tela de Configurações
  - O que fazer: em `lib/views/settings/settingsPage.dart`, substituir `_buildNotificationsSwitch()` (o switch único atual) por um `ListTile` de navegação para `AppRoutes.notificationsPage`, no mesmo padrão de `_buildAccountListTile()` e `_buildAboutListTile()` (ícone `Icons.notifications`, título "Notificações", `trailing: Icon(Icons.chevron_right)`, `onTap: () => Get.toNamed(AppRoutes.notificationsPage)`). Remover o import de `onesignal_flutter` e a lógica de opt-in/opt-out desse arquivo, já que passam a viver em `notificationsPage.dart` (task 5).
  - Arquivos: `lib/views/settings/settingsPage.dart`
  - Pronto quando: a tela de Configurações não tem mais lógica de notificação embutida, apenas navega para a tela dedicada.
  - Depende de: 5

---

## Feature: API de Notificações em Fastify + TypeScript (setup completo)

### Contexto
Repositório novo e separado do app Flutter, em `C:\Users\pedroh.monteiro\dev\sicoob\estudazz-api` (hoje uma pasta vazia, ainda sem `git init`), que centraliza o envio de push via OneSignal (removendo a REST API Key do cliente) e adiciona o que falta hoje: agendamento preciso de lembretes, push imediato para sala de estudo, broadcast administrativo e reengajamento por inatividade. Todos os caminhos de arquivo abaixo são relativos à raiz desse repositório. Ele será deployado no Railway como um serviço próprio, apontando para essa raiz.

### Tarefas

- [x] 7. Inicializar o projeto Node/TypeScript
  - O que fazer: em `C:\Users\pedroh.monteiro\dev\sicoob\estudazz-api`, rodar `git init`, criar `package.json` (nome, scripts `dev`/`build`/`start`/`test`/`lint`), `tsconfig.json` (`target: ES2022`, `module: NodeNext`, `strict: true`, `outDir: dist`), `.gitignore` (`node_modules`, `dist`, `.env`), `.nvmrc` fixando Node 20. Gerenciador de pacotes é **pnpm**: rodar `pnpm init` (ou ajustar o `package.json` manualmente), adicionar `"packageManager": "pnpm@9.x"` no `package.json` e criar um `pnpm-workspace.yaml` vazio só se necessário (projeto único, sem workspaces, então não é obrigatório).
  - Arquivos: `package.json`, `tsconfig.json`, `.gitignore`, `.nvmrc` (raiz do repo `estudazz-api`, todos novos)
  - Pronto quando: `pnpm install` roda sem erro e `pnpm build` compila um `src/server.ts` mínimo sem erros; o diretório já é um repositório git com o primeiro commit (incluindo o `pnpm-lock.yaml` versionado).
  - Depende de: nenhuma

- [x] 8. Configurar o Fastify base + plugins essenciais
  - O que fazer: instalar com `pnpm add fastify @fastify/cors @fastify/helmet @fastify/rate-limit` e `pnpm add -D pino-pretty`. Criar `app.ts` exportando `buildApp()` que registra os plugins e o logger estruturado; `server.ts` chama `buildApp().listen({ port: env.PORT, host: '0.0.0.0' })`.
  - Arquivos: `src/app.ts`, `src/server.ts` (novos)
  - Pronto quando: `pnpm dev` sobe o servidor na porta definida por `PORT`, com logs estruturados no console.
  - Depende de: 7

- [x] 9. Rota de health check
  - O que fazer: `GET /health` retornando `{ status: 'ok', uptime: process.uptime() }`.
  - Arquivos: `src/routes/health.ts` (novo)
  - Pronto quando: `curl localhost:<PORT>/health` retorna 200 com o payload esperado.
  - Depende de: 8

- [x] 10. Configuração de variáveis de ambiente tipada e validada
  - O que fazer: usar `zod` para declarar o schema de env vars (`PORT`, `DATABASE_URL`, `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_BASE64`, `ADMIN_API_KEY`, `INACTIVITY_THRESHOLD_DAYS` com default `7`), parseando `process.env` no boot e lançando erro claro (nome da variável faltando) se algo estiver inválido. Criar `.env.example` documentando cada uma com comentário.
  - Arquivos: `src/config/env.ts`, `.env.example` (novos)
  - Pronto quando: subir o servidor sem uma variável obrigatória falha com mensagem apontando exatamente qual falta; com todas setadas, sobe normalmente.
  - Depende de: 7

- [x] 11. Cliente OneSignal (envio imediato, agendamento, cancelamento, broadcast)
  - O que fazer: criar um wrapper sobre a API REST do OneSignal (`fetch` nativo do Node 20, sem necessidade de lib extra) com 4 funções: `sendImmediate({ externalIds, title, body, data })`, `scheduleNotification({ externalIds, title, body, sendAfter, data })` retornando `{ oneSignalId }`, `cancelNotification(oneSignalId)`, `broadcastToAll({ title, body, data })` (usando `included_segments: ["Subscribed Users"]`). Todas usam `Authorization: Basic ${env.ONESIGNAL_REST_API_KEY}` e `app_id: env.ONESIGNAL_APP_ID`; lançam um erro tipado em respostas não-2xx.
  - Arquivos: `src/services/oneSignalClient.ts` (novo)
  - Pronto quando: coberto pelos testes da task 21 com `fetch` mockado, validando o payload de cada função.
  - Depende de: 10

- [x] 12. Cliente Firebase Admin (verificação de token + Firestore somente leitura)
  - O que fazer: inicializar `firebase-admin` a partir de `env.FIREBASE_SERVICE_ACCOUNT_BASE64` (decodificar base64 → JSON → `credential.cert(...)`). Exportar `verifyIdToken(token: string)` e uma instância `firestore` (Admin Firestore), usada só para leitura (checagem de membros de sala e leitura de `last_login`).
  - Arquivos: `src/plugins/firebaseAdmin.ts` (novo)
  - Pronto quando: com um service account válido, `verifyIdToken` resolve um token real emitido pelo Firebase Auth do projeto.
  - Depende de: 10

- [x] 13. Middleware de autenticação de usuário (Firebase ID Token)
  - O que fazer: criar um hook `onRequest` (`authenticateUser`) que lê `Authorization: Bearer <idToken>`, chama `verifyIdToken`, e decora `request.userId = decoded.uid`; responde 401 `{ error: 'unauthorized' }` se o header estiver ausente ou o token for inválido. Adicionar a augmentation de tipos do Fastify para `request.userId: string`.
  - Arquivos: `src/plugins/authenticate.ts`, `src/types/fastify.d.ts` (novos)
  - Pronto quando: request sem token retorna 401; com token válido, `request.userId` fica disponível na rota (validado pelos testes da task 21).
  - Depende de: 12

- [x] 14. Middleware de autenticação de admin (broadcast)
  - O que fazer: hook `onRequest` (`authenticateAdmin`) comparando o header `x-admin-key` com `env.ADMIN_API_KEY` usando `crypto.timingSafeEqual` (evitar timing attack); 401 em caso de divergência ou ausência.
  - Arquivos: `src/plugins/authenticateAdmin.ts` (novo)
  - Pronto quando: a rota de broadcast (task 18) rejeita requisições sem a chave correta.
  - Depende de: 10

- [x] 15. Banco de dados: schema Prisma + client
  - O que fazer: modelar `ScheduledReminder { id String @id @default(cuid()), userId String, type String, entityId String, oneSignalId String, remindAt DateTime, createdAt DateTime @default(now()), @@unique([userId, type, entityId]) }` e `ReengagementLog { userId String @id, sentAt DateTime }` (usado pela task 19). Criar um plugin Fastify que expõe o `PrismaClient` como singleton.
  - Arquivos: `prisma/schema.prisma`, `src/plugins/prisma.ts` (novos)
  - Pronto quando: `pnpm add prisma -D && pnpm add @prisma/client`, seguido de `pnpm exec prisma migrate dev`, gera a migração com sucesso contra um Postgres local (ex: via Docker), e o client é importável sem erro de tipos.
  - Depende de: 7

- [x] 16. Rota: agendar/cancelar lembrete (tarefas e eventos)
  - O que fazer: `POST /v1/notifications/reminders` (auth de usuário) com body `{ type: 'task' | 'event', entityId: string, title: string, body: string, remindAt: string (ISO 8601) }`. Fluxo: se já existir um `ScheduledReminder` para `[userId, type, entityId]`, cancelar o `oneSignalId` antigo antes de recriar (upsert); chamar `oneSignalClient.scheduleNotification` com `externalIds: [request.userId]`; salvar o registro. `DELETE /v1/notifications/reminders/:type/:entityId` (auth de usuário): busca o registro por `[userId, type, entityId]`, cancela no OneSignal se existir, remove do banco — idempotente (204 mesmo se não existir).
  - Arquivos: `src/routes/reminders.ts` (novo)
  - Pronto quando: o fluxo agendar → reagendar → cancelar é validado pelos testes da task 21 com OneSignal mockado.
  - Depende de: 11, 13, 15

- [x] 17. Rota: push imediato para sala de estudo
  - O que fazer: `POST /v1/notifications/study-rooms/:roomId/push` (auth de usuário) com body `{ recipientUids: string[], title: string, body: string, data?: object }`. Antes de disparar, validar via `firestore.collection('study_rooms').doc(roomId).get()` que `request.userId` e todos os `recipientUids` estão em `members` — 403 se não estiverem (evita abuso do endpoint para enviar push arbitrário). Chamar `oneSignalClient.sendImmediate` para os `recipientUids` (excluindo o próprio remetente, se presente na lista).
  - Arquivos: `src/routes/studyRoomPush.ts` (novo)
  - Pronto quando: chamada com um uid fora da sala retorna 403; chamada válida dispara o push (mockado) só para os destinatários corretos.
  - Depende de: 11, 12, 13

- [x] 18. Rota: broadcast administrativo (novidades do app)
  - O que fazer: `POST /v1/notifications/broadcast` (auth de admin, header `x-admin-key`) com body `{ title: string, body: string, data?: object }`, chamando `oneSignalClient.broadcastToAll`. Feito para ser disparado manualmente ou por um passo de CI ao publicar uma nova versão do app.
  - Arquivos: `src/routes/broadcast.ts` (novo)
  - Pronto quando: request sem `x-admin-key` correto retorna 401; com a chave correta, chama o OneSignal com `included_segments`.
  - Depende de: 11, 14

- [x] 19. Job de reengajamento por inatividade
  - O que fazer: usando `node-cron`, agendar uma execução diária (ex: `0 12 * * *`) que consulta `firestore.collection('users').where('last_login', '<', <agora - INACTIVITY_THRESHOLD_DAYS dias>)`, e para cada usuário elegível verifica em `ReengagementLog` se já foi notificado nos últimos `INACTIVITY_THRESHOLD_DAYS` dias (evita reenvio diário para quem já recebeu); envia push via `oneSignalClient.sendImmediate` e grava/atualiza o `ReengagementLog`. Registrar o start do cron em `server.ts`.
  - Arquivos: `src/jobs/inactivityJob.ts` (novo), `src/server.ts`
  - Pronto quando: rodando localmente com Firestore/Prisma mockados, o job notifica apenas usuários elegíveis e não duplica envio em execuções repetidas dentro da mesma janela.
  - Depende de: 11, 12, 15

- [x] 20. Registro central de rotas + tratamento de erros padronizado
  - O que fazer: `routes/index.ts` registrando `health`, `reminders`, `studyRoomPush`, `broadcast` (todas exceto `health` sob o prefixo `/v1`). `setErrorHandler` global no `app.ts` padronizando respostas de erro como `{ error: string, message: string }`, mapeando erros de validação (Zod/JSON Schema) para 400, erros de auth para 401/403, erros do OneSignal para 502, e qualquer erro não tratado para 500 sem vazar stack trace quando `NODE_ENV=production`.
  - Arquivos: `src/routes/index.ts`, `src/app.ts`
  - Pronto quando: payload inválido retorna 400 no formato padronizado; erro inesperado retorna 500 sem detalhes internos em produção.
  - Depende de: 9, 16, 17, 18

- [x] 21. Testes automatizados do backend
  - O que fazer: configurar `vitest` (`pnpm add -D vitest`). Cobrir com `app.inject()` (mockando `oneSignalClient` e `firebaseAdmin` via `vi.mock`): 401 sem token nas rotas de usuário; 400 em payload inválido; fluxo completo de agendar/reagendar/cancelar lembrete; 403 ao tentar dar push numa sala da qual não é membro; 401 no broadcast sem `x-admin-key`; payloads corretos enviados ao `oneSignalClient` em cada função (task 11).
  - Arquivos: `test/reminders.test.ts`, `test/studyRoomPush.test.ts`, `test/oneSignalClient.test.ts`, `vitest.config.ts` (novos)
  - Pronto quando: `pnpm test` roda todos os testes e passa localmente sem depender de rede real (OneSignal e Firebase totalmente mockados).
  - Depende de: 16, 17, 18

- [ ] 22. Preparar deploy no Railway
  - O que fazer: definir `package.json` scripts finais — `"build": "prisma generate && tsc"`, `"start": "prisma migrate deploy && node dist/server.js"`, `"dev": "tsx watch src/server.ts"`. Manter o `"packageManager": "pnpm@9.x"` (task 7) e o `pnpm-lock.yaml` versionado — é isso que faz o Nixpacks do Railway detectar pnpm automaticamente e rodar `pnpm install --frozen-lockfile` no build. Criar `railway.json` com `builder: NIXPACKS` e `startCommand` explícito (`pnpm start`). Conferir que `.env.example` documenta todas as vars exigidas por `config/env.ts` (task 10), incluindo `DATABASE_URL` do plugin Postgres do Railway. Criar o serviço no Railway apontando para o repositório `estudazz-api` (raiz, sem subdiretório).
  - Arquivos: `railway.json` (novo), `package.json`, `.env.example`
  - Pronto quando: `pnpm build` seguido de `pnpm start` (com um Postgres local configurado em `DATABASE_URL`) sobe o servidor sem erro, replicando o que o Railway vai executar.
  - Depende de: 10, 15, 20

---

## Feature: Integração do app Flutter com a API de Notificações

### Contexto
Com a API no ar (Feature 2, repo `estudazz-api`), o app Flutter precisa efetivamente chamá-la nos pontos onde hoje nada acontece: criar tarefa, criar/editar evento, entrar em sala de estudo, enviar mensagem no chat da sala. Hoje `TasksDB.addTask` e `EventsDB.addEvent` descartam a `DocumentReference` retornada pelo Firestore, então o primeiro passo é expor o id do documento criado. Todas as tarefas abaixo são commitadas na branch criada na task 1.

### Tarefas

- [x] 23. Adicionar variável de ambiente da API de notificações ao app
  - O que fazer: adicionar `NOTIFICATIONS_API_BASE_URL` ao `.env.example` da raiz do projeto Flutter com a URL do serviço `estudazz-api` publicado no Railway (task 22) como exemplo. Adicionar o campo `@EnviedField` correspondente (`notificationsApiBaseUrl`) na classe `Env` local, seguindo o mesmo padrão já usado para `appIdOnesignalKey` — **atenção:** o `.gitignore` deste repo tem o padrão `env.*`, que provavelmente também exclui do controle de versão o arquivo-fonte anotado com `@Envied` (não só o `.g.dart` gerado); ele só existe localmente na sua máquina, então localize-o manualmente antes de editar. Depois, regenerar com `dart run build_runner build --delete-conflicting-outputs`.
  - Arquivos: `.env.example` (raiz do repo Flutter), arquivo local não versionado da classe `Env` (provavelmente `lib/env.dart`)
  - Pronto quando: `Env.notificationsApiBaseUrl` fica acessível em qualquer arquivo do app após a regeneração.
  - Depende de: 1

- [x] 24. Criar o serviço cliente HTTP da API de notificações
  - O que fazer: classe `NotificationsApiService` usando `Dio` (já é dependência do projeto) com `baseUrl: Env.notificationsApiBaseUrl` e um interceptor que injeta `Authorization: Bearer <idToken>` chamando `FirebaseAuth.instance.currentUser?.getIdToken()` a cada requisição. Métodos: `scheduleReminder({ required String type, required String entityId, required String title, required String body, required DateTime remindAt })` → `POST /v1/notifications/reminders`; `cancelReminder({ required String type, required String entityId })` → `DELETE /v1/notifications/reminders/:type/:entityId`; `pushToStudyRoom({ required String roomId, required List<String> recipientUids, required String title, required String body })` → `POST /v1/notifications/study-rooms/:roomId/push`. Todos os métodos capturam exceções internamente (`try/catch` + `debugPrint`) — notificação é funcionalidade auxiliar e não pode travar o fluxo principal (criar tarefa, enviar mensagem etc.) se a API estiver fora do ar.
  - Arquivos: `lib/services/notificationsApi/notificationsApiService.dart` (novo)
  - Pronto quando: os 3 métodos compilam e nenhum lança exceção não tratada mesmo com a API indisponível (testável apontando `NOTIFICATIONS_API_BASE_URL` para uma porta fechada).
  - Depende de: 23, 16, 17 (contrato definido no repo `estudazz-api`)

- [x] 25. Ajustar `TasksDB.addTask` e `EventsDB.addEvent` para retornar o documento criado
  - O que fazer: mudar a assinatura de `TasksDB.addTask` para `Future<DocumentReference> addTask(...)`, retornando o resultado de `tasksCollection.add(...)` em vez de descartá-lo. Mesma mudança em `EventsDB.addEvent` → `Future<DocumentReference> addEvent(...)`.
  - Arquivos: `lib/services/db/tasks/tasksDB.dart`, `lib/services/db/calendar/eventsDB.dart`
  - Pronto quando: os dois métodos retornam a `DocumentReference` do documento criado; nenhum outro call site depende do retorno `void` anterior (nenhum ajuste extra necessário fora dos controllers das tasks 27/28).
  - Depende de: 1

- [x] 26. Criar `EventController.deleteEvent` e usá-lo em `detailEventDialog.dart`
  - O que fazer: adicionar `Future<void> deleteEvent(String eventId) => eventsDB.deleteEvent(eventId);` ao `EventController`. Trocar a chamada direta `EventsDB().deleteEvent(eventId)` em `detailEventDialog.dart` (linha ~74) por uma instância de `EventController` + `.deleteEvent(eventId)`, no mesmo padrão já usado em `editEventDialog.dart`.
  - Arquivos: `lib/controllers/calendar/eventController.dart`, `lib/components/dialog/calendar/detailEventDialog.dart`
  - Pronto quando: excluir um evento continua funcionando e passa a passar pelo `EventController`.
  - Depende de: 1

- [x] 27. Disparar e cancelar lembrete de tarefa (criar / concluir / desmarcar / excluir)
  - O que fazer: em `TaskController.addTask`, após `tasksDB.addTask(...)` retornar com sucesso, checar `SharedPreferences.getBool('notif_pref_tasks') ?? true` e, se ativado, chamar `NotificationsApiService().scheduleReminder(type: 'task', entityId: doc.id, title: 'Tarefa pendente', body: taskName, remindAt: dueDate)`. Em `markTaskCompletedDialog.dart`: no branch que marca como concluída e no branch de excluir (linhas ~68 e ~174), após a operação no Firestore, chamar `cancelReminder(type: 'task', entityId: taskId)`; no branch que desmarca, também cancelar (sem reagendar — a UI atual não permite editar a `due_date` de uma tarefa, então reagendar fica fora de escopo até isso existir).
  - Arquivos: `lib/controllers/tasks/taskController.dart`, `lib/components/dialog/task/markTaskCompletedDialog.dart`
  - Pronto quando: criar uma tarefa agenda um lembrete; concluir, desmarcar ou excluir cancelam o lembrete correspondente; nenhum fluxo trava se a API estiver fora do ar.
  - Depende de: 24, 25

- [x] 28. Disparar, reagendar e cancelar lembrete de evento (criar / editar / excluir)
  - O que fazer: em `EventController.addEvent`, após sucesso, checar `notif_pref_events` e chamar `scheduleReminder(type: 'event', entityId: doc.id, title: 'Evento', body: eventName, remindAt: eventDate)`. Em `EventController.updateEvent`, após sucesso, chamar o mesmo método (o endpoint da task 16 faz upsert, reagendando automaticamente com a nova data). Em `EventController.deleteEvent` (task 26), chamar `cancelReminder(type: 'event', entityId: eventId)`.
  - Arquivos: `lib/controllers/calendar/eventController.dart`
  - Pronto quando: criar ou editar um evento agenda/reagenda o lembrete; excluir cancela.
  - Depende de: 24, 25, 26

- [x] 29. Disparar push ao entrar em uma sala de estudo
  - O que fazer: em `StudyRoomController.joinStudyRoom`, após `_studyRoomDB.addUserToRoom(room.id, user.uid)` (linha ~104), checar `notif_pref_studyroom` e chamar `NotificationsApiService().pushToStudyRoom(roomId: room.id, recipientUids: room.members, title: 'Nova pessoa na sala', body: '${user.displayName ?? "Alguém"} entrou em "${room.name}"')` — usar `room.members` de antes do join, que já exclui o próprio usuário entrando.
  - Arquivos: `lib/controllers/studyRoom/studyRoomController.dart`
  - Pronto quando: entrar em uma sala existente dispara um push para os membros já presentes.
  - Depende de: 24

- [ ] 30. Disparar push ao enviar mensagem na sala de estudo
  - O que fazer: em `_ChatPageState._sendMessage`, após `_studyRoomDB.sendChatMessage(...)` (linha ~33), montar `recipientUids = widget.room.members.where((uid) => uid != currentUser?.uid).toList()`, checar `notif_pref_studyroom` e chamar `NotificationsApiService().pushToStudyRoom(roomId: widget.room.id, recipientUids: recipientUids, title: widget.room.name, body: '${_membersMap[currentUser?.uid]?.displayName ?? "Alguém"}: ${_textController.text.trim()}')` antes de limpar o campo de texto.
  - Arquivos: `lib/views/studyRoom/chatPage.dart`
  - Pronto quando: enviar uma mensagem dispara push para os demais membros da sala.
  - Depende de: 24

- [ ] 31. Remover o cliente OneSignal inseguro do app e a REST API Key do cliente
  - O que fazer: apagar `oneSignalService.dart` — o método `sendPushNotification` nunca é chamado em nenhum lugar do app hoje, e expõe a REST API Key do OneSignal dentro do binário (qualquer pessoa pode extrair a chave via engenharia reversa e disparar notificações para qualquer usuário). Remover o campo `oneSignalRestApiKey` da classe `Env` local e a variável correspondente do `.env` local — a partir de agora só o backend Fastify (repo `estudazz-api`, task 11) guarda essa chave.
  - Arquivos: `lib/services/onesignal/oneSignalService.dart` (excluir), arquivo local da classe `Env`
  - Pronto quando: nenhuma referência a `oneSignalRestApiKey`/`OneSignalService` resta no app; o app compila normalmente.
  - Depende de: 11

---

## Feature: Documentação da API e abertura do PR

### Contexto
Documento único para você conseguir rodar a API localmente, fazer o deploy no Railway e confirmar que o app está corretamente ligado a ela, sem precisar recorrer a este plano depois de pronto. Ao final, a branch criada na task 1 (com as Features 1 e 3) vira um PR.

### Tarefas

- [ ] 32. Criar `README.md` no repo `estudazz-api` com o contrato completo e guia de deploy/integração
  - O que fazer: documento cobrindo — visão geral e arquitetura (relay reativo às chamadas do app + job interno de reengajamento); todas as rotas com método, path, headers, body e respostas/códigos de erro (`POST`/`DELETE /v1/notifications/reminders`, `POST /v1/notifications/study-rooms/:roomId/push`, `POST /v1/notifications/broadcast`, `GET /health`); autenticação (Firebase ID Token nas rotas de usuário, `x-admin-key` no broadcast) e como o app Flutter obtém e envia o token, referenciando `NotificationsApiService` (task 24); todas as variáveis de ambiente exigidas (task 10) com exemplos; como rodar localmente (Postgres via Docker, `pnpm install`, `pnpm dev`, `pnpm exec prisma migrate dev`); passo a passo de deploy no Railway (criar serviço a partir do repositório `estudazz-api`, provisionar o plugin de Postgres e copiar `DATABASE_URL`, configurar as demais env vars, pegar o domínio público gerado); como apontar o app Flutter para a URL final (`NOTIFICATIONS_API_BASE_URL`, task 23).
  - Arquivos: `README.md` (novo, raiz do repo `estudazz-api`)
  - Pronto quando: seguindo o README do zero, sem contexto prévio, é possível subir a API localmente, fazer deploy no Railway e configurar o app para usá-la.
  - Depende de: 22, 31

- [ ] 33. Abrir o PR da branch do Flutter
  - O que fazer: com as Features "Branch e modal" e "Integração do app Flutter" commitadas na branch da task 1, dar push da branch e abrir um PR contra `main` no repositório do Flutter, descrevendo o que foi feito (modal personalizado + gatilhos reais de notificação) e linkando o repositório/documentação da API (`estudazz-api`, task 32) para quem for revisar.
  - Arquivos: nenhum (ação de git/GitHub)
  - Pronto quando: existe um PR aberto da branch da task 1 contra `main`, com a descrição citando a API `estudazz-api` e seu README.
  - Depende de: 32
