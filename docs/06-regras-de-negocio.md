# 📏 Regras de Negócio — Igreja Manager

## 1. Regras Gerais

### RN-GER-001: Multi-tenancy
- Todo registro deve pertencer a uma igreja (`church_id`).
- Um usuário só pode acessar dados da igreja à qual está vinculado.
- Super admins podem acessar dados de múltiplas igrejas.
- Nenhuma consulta deve retornar dados de outra igreja — isso deve ser garantido em **todas** as queries.

### RN-GER-002: Soft Delete
- Registros críticos (membros, lançamentos financeiros, bens) não são excluídos fisicamente.
- Utiliza-se campo `deleted_at` para marcar exclusão lógica.
- Registros com `deleted_at IS NOT NULL` não aparecem em listagens padrão.
- Apenas super admins podem ver/restaurar registros excluídos.

### RN-GER-003: Auditoria
- Toda criação, edição e exclusão de registros deve gerar um log de auditoria.
- O log deve conter: usuário, ação, entidade, id da entidade, valores anteriores e novos.
- Logs de auditoria são **imutáveis** — não podem ser editados ou excluídos.

### RN-GER-004: Timestamps
- Todos os registros possuem `created_at` e `updated_at`.
- `created_at` é definido na criação e nunca alterado.
- `updated_at` é atualizado automaticamente a cada modificação.
- Todas as datas/horas são armazenadas em UTC.
- A conversão para o fuso horário local é feita no frontend.

---

## 2. Regras do Módulo de Autenticação

### RN-AUTH-001: Política de Senhas
- Mínimo de 8 caracteres.
- Deve conter pelo menos: 1 letra maiúscula, 1 letra minúscula, 1 número.
- Caracteres especiais são recomendados mas não obrigatórios.
- Hash com Argon2id — nunca armazenar senha em texto puro.

### RN-AUTH-002: Bloqueio por Tentativas
- Após 5 tentativas de login falhas consecutivas, a conta é bloqueada por 15 minutos.
- O contador é resetado após um login bem-sucedido.
- Super admins podem desbloquear contas manualmente.

### RN-AUTH-003: Tokens JWT
- **Access Token**: validade de 15 minutos.
- **Refresh Token**: validade de 7 dias.
- Refresh token é de uso único (rotacionado a cada renovação).
- Logout revoga o refresh token — o access token expira naturalmente.
- O token contém: `user_id`, `church_id`, `role`, `permissions`.

### RN-AUTH-004: Permissões
- As permissões seguem o padrão: `módulo:ação`
  - Exemplo: `members:read`, `members:write`, `members:delete`
  - Wildcard: `members:*` = todas as ações no módulo
  - Super wildcard: `*` = acesso total
- Verificação de permissão ocorre em **todo** endpoint protegido.
- Um usuário não pode elevar suas próprias permissões.
- Apenas super admin ou pastor pode criar/editar usuários.

### RN-AUTH-005: Troca de Senha
- Ao trocar a senha, todos os refresh tokens do usuário são revogados.
- O link de redefinição de senha expira em 2 horas e é de uso único.
- Não é permitido reutilizar as últimas 3 senhas.

---

## 3. Regras do Módulo de Membros

### RN-MEM-001: Cadastro Obrigatório
- Campos obrigatórios para cadastro mínimo:
  - Nome completo
  - Data de nascimento
  - Sexo
  - Telefone principal
- Demais campos podem ser preenchidos posteriormente.

### RN-MEM-002: Validação de CPF
- Se informado, o CPF deve ser válido (algoritmo de verificação).
- CPF é único por igreja — não pode haver dois membros com o mesmo CPF na mesma igreja.
- CPF pode ser duplicado entre igrejas diferentes (são entidades independentes).

### RN-MEM-003: Status do Membro
- **Fluxo de status permitido:**
  ```
  visitante → congregado → ativo
  ativo → inativo
  ativo → transferido
  ativo → desligado
  ativo → falecido
  inativo → ativo (reconciliação/reintegração)
  transferido → ativo (retorno com nova transferência)
  desligado → ativo (reconciliação)
  ```
- Toda mudança de status deve registrar: data, motivo e usuário responsável.
- Toda mudança de status gera um evento no histórico do membro.

### RN-MEM-004: Cargos Eclesiásticos
- Hierarquia de cargos: `pastor > evangelista > presbítero > diácono > cooperador > membro > congregado`
- Mudança de cargo gera evento no histórico.
- A data de consagração é obrigatória ao atribuir cargo a partir de cooperador.
- Um membro só pode ter **um** cargo eclesiástico por vez.

### RN-MEM-005: Famílias
- Uma família deve ter pelo menos um membro (o chefe).
- Um membro pode pertencer a apenas **uma** família.
- Ao definir endereço da família, os membros vinculados podem herdar o endereço.
- A exclusão de uma família desvincula os membros, mas não os exclui.

### RN-MEM-006: Ministérios
- Um membro pode participar de **múltiplos** ministérios.
- Cada ministério deve ter um líder responsável.
- Ao tornar um membro inativo/transferido/desligado, suas participações em ministérios devem ser encerradas automaticamente.

### RN-MEM-007: Idade e Aniversários
- A idade é calculada automaticamente a partir da data de nascimento.
- Aniversariantes são calculados pelo dia e mês (ignorando o ano).
- O sistema deve ser capaz de listar aniversariantes por semana e por mês.

### RN-MEM-008: Busca por Nome
- A busca de membros por nome deve ser **case-insensitive** e desconsiderar acentos.
  - Exemplo: buscar "jose" deve encontrar "José".
- A busca parcial deve funcionar (digitou "Mar" → encontra "Maria", "Marcos", "Marcelo").

---

## 4. Regras do Módulo Financeiro

### RN-FIN-001: Princípio da Partida Simples
- O sistema utiliza **partida simples** (entrada e saída), adequado à gestão eclesiástica.
- Cada lançamento é uma receita OU uma despesa — nunca ambos.
- O saldo é calculado como: `saldo_inicial + total_receitas - total_despesas`.

### RN-FIN-002: Lançamento de Receita
- Todo lançamento de receita deve ter: data, categoria, valor, forma de recebimento.
- O valor deve ser positivo e maior que zero.
- Dízimos **devem** estar vinculados a um membro (campo obrigatório).
- Ofertas **podem** estar vinculadas a um membro (campo opcional).

### RN-FIN-003: Lançamento de Despesa
- Todo lançamento de despesa deve ter: data, categoria, valor, descrição.
- Despesas podem ter status: pendente, confirmado (pago), cancelado.
- Despesas pendentes não afetam o saldo até serem confirmadas.
- Despesas com data de vencimento geram alertas quando próximas do vencimento.

### RN-FIN-004: Formas de Pagamento
- Formas aceitas: dinheiro, PIX, transferência bancária, cartão de débito, cartão de crédito, cheque, boleto.
- A forma de pagamento é informativa e não altera o fluxo do lançamento.

### RN-FIN-005: Dízimos — Regras de Sigilo
- **O valor do dízimo de cada membro é informação confidencial.**
- Apenas usuários com permissão `financial:tithes` podem:
  - Ver valores individuais de dízimos
  - Gerar relatórios nominais de dízimos
  - Emitir declarações de dízimos
- Relatórios públicos (para assembleia) mostram apenas o **total de dízimos**, nunca valores individuais.
- O membro pode solicitar sua própria declaração anual de dízimos.

### RN-FIN-006: Dízimos — Regularidade
- Um membro é considerado **dizimista regular** se contribuiu em pelo menos 10 dos últimos 12 meses.
- Um membro é considerado **dizimista irregular** se contribuiu em 6 a 9 dos últimos 12 meses.
- Abaixo de 6 meses, é considerado **não dizimista ativo**.
- Esses status são calculados automaticamente e não ficam visíveis ao membro.

### RN-FIN-007: Fechamento Mensal
- O fechamento mensal consolida os dados do mês e impede alterações retroativas.
- Após o fechamento:
  - Lançamentos do período **não podem ser editados** — apenas estornados.
  - Estornos geram um novo lançamento compensatório, mantendo o registro original.
- O fechamento registra: total receitas, total despesas, saldo do período, saldo acumulado.
- Apenas usuários com permissão `financial:close` podem executar o fechamento.
- O fechamento pode ser desfeito apenas pelo super admin.

### RN-FIN-008: Campanhas Financeiras
- Uma campanha tem data de início obrigatória. A data de término é opcional (campanha por tempo indeterminado).
- O progresso da campanha é calculado: `(arrecadado / meta) * 100`.
- Se a campanha não tem meta definida, mostra apenas o total arrecadado.
- Ao encerrar uma campanha, nenhum novo lançamento pode ser vinculado a ela.
- Todo lançamento vinculado a uma campanha também é contabilizado no financeiro geral.

### RN-FIN-009: Contas Bancárias
- Deve existir pelo menos uma conta (caixa) para realizar lançamentos.
- Todo lançamento deve estar vinculado a uma conta.
- Transferências entre contas geram dois lançamentos: despesa na origem e receita no destino.
- O saldo de cada conta é mantido separadamente.

### RN-FIN-010: Estornos
- Um estorno gera um lançamento inverso com referência ao lançamento original.
- O lançamento original é marcado como "estornado" e não editável.
- O estorno deve informar o motivo obrigatoriamente.
- Estornos são contabilizados na data em que são realizados, não na data original.

### RN-FIN-011: Relatório de Prestação de Contas
- O relatório mensal para assembleia deve conter:
  - Saldo anterior
  - Total de receitas por categoria
  - Total de despesas por categoria
  - Saldo final
  - Sem valores individuais de dízimos
- Formato PDF com cabeçalho da igreja (nome, CNPJ, logo).

---

## 5. Regras do Módulo de Patrimônio

### RN-PAT-001: Código de Tombamento
- Todo bem recebe um código único no formato `PAT-XXXXXX` (sequencial por igreja).
- O código é gerado automaticamente e não pode ser alterado.
- O código deve ser afixado fisicamente no bem (etiqueta/plaqueta).

### RN-PAT-002: Classificação de Bens
- Bens são categorizados em pelo menos: imóveis, veículos, equipamentos de som, instrumentos musicais, mobiliário, informática, cozinha, projeção.
- Subcategorias podem ser criadas pelo usuário.
- A categoria define a taxa de depreciação padrão.

### RN-PAT-003: Ciclo de Vida do Bem
```
Cadastro (ativo) → Em manutenção → Ativo (após manutenção)
                 → Cedido (emprestado)
                 → Baixado (sucata, perda, furto)
                 → Alienado (venda, doação)
```
- Toda mudança de status registra data e motivo.
- Bens baixados ou alienados não podem voltar ao status ativo.
- Bens cedidos são retornados via módulo de empréstimos.

### RN-PAT-004: Depreciação
- A depreciação é calculada pelo método linear:
  - `Depreciação mensal = (Valor aquisição - Valor residual) / Vida útil em meses`
- O cálculo é executado mensalmente (pode ser automatizado ou sob demanda).
- O valor atual do bem: `Valor aquisição - Depreciação acumulada`.
- O valor atual nunca fica abaixo do valor residual.
- Bens recebidos por doação podem ter valor de aquisição estimado.

### RN-PAT-005: Manutenções
- Manutenções preventivas podem gerar alerta de próxima manutenção.
- O custo da manutenção pode gerar um lançamento de despesa no módulo financeiro (integração).
- Ao registrar manutenção, o status do bem muda para "em manutenção".
- Ao concluir a manutenção, o status retorna a "ativo".

### RN-PAT-006: Inventários
- Um inventário aberto lista todos os bens ativos para conferência.
- Cada bem deve ser conferido individualmente (encontrado, não encontrado, divergência).
- Após a conferência de todos os itens, o inventário pode ser "fechado".
- Bens não encontrados geram alerta e podem ser marcados como "baixados".
- Divergências (estado diferente do cadastrado) devem ser anotadas.
- Recomendação: realizar inventário ao menos uma vez ao ano.

### RN-PAT-007: Empréstimos de Bens
- O empréstimo só pode ser feito para membros cadastrados.
- O estado do bem deve ser registrado na saída e na devolução.
- Empréstimos com devolução atrasada geram alerta.
- Um bem emprestado fica com status "cedido" até a devolução.
- Não é possível emprestar um bem que já está emprestado, em manutenção ou baixado.
- Pode ser gerado um termo de responsabilidade (PDF) para o membro assinar.

---

## 6. Regras do Módulo EBD

### RN-EBD-001: Trimestres/Períodos
- A EBD é organizada em períodos (geralmente trimestres).
- Apenas um período pode estar **ativo** por vez.
- As turmas e matrículas são vinculadas a um período.
- Ao iniciar um novo período, as turmas podem ser clonadas do período anterior.

### RN-EBD-002: Turmas
- Cada turma deve ter pelo menos um professor titular.
- A capacidade máxima, se definida, não pode ser excedida nas matrículas.
- A faixa etária é informativa — o sistema alerta, mas não bloqueia matrículas fora da faixa.
- Turmas inativas não aparecem na lista de chamada.

### RN-EBD-003: Matrículas
- Um aluno pode estar matriculado em apenas **uma** turma por período.
- Visitantes podem ser registrados na chamada sem matrícula formal.
- A transferência entre turmas encerra a matrícula anterior e cria uma nova.
- Ao cancelar matrícula, o histórico de frequência é mantido.

### RN-EBD-004: Chamada (Frequência)
- A chamada é registrada por **turma** e por **data** (geralmente domingos).
- Cada aluno matriculado pode ter status: presente, ausente, justificado.
- Registros opcionais por presença:
  - Trouxe Bíblia (sim/não)
  - Trouxe revista/material (sim/não)
  - Valor da oferta individual
- Visitantes são registrados como presentes com flag `is_visitor = true`.
- Visitantes não cadastrados informam apenas o nome.
- A chamada pode ser editada até 7 dias após a data da aula. Depois, fica somente leitura.

### RN-EBD-005: Controle de Frequência
- Percentual de presença por aluno: `(presenças / total_aulas) * 100`
- Aluno com mais de 3 ausências consecutivas (sem justificativa) gera alerta.
- A frequência mínima recomendada é 75% para o trimestre.
- Os indicadores são:
  - **Excelente**: ≥ 90%
  - **Bom**: 75% — 89%
  - **Regular**: 50% — 74%
  - **Insuficiente**: < 50%

### RN-EBD-006: Ofertas da EBD
- As ofertas da EBD são registradas individualmente na chamada.
- O total de ofertas por aula é calculado automaticamente.
- As ofertas da EBD podem gerar um lançamento de receita no módulo financeiro (integração opcional).
- A oferta é registrada por aluno, mas o relatório público mostra apenas o total.

### RN-EBD-007: Relatórios EBD
- O relatório trimestral consolida:
  - Número de turmas ativas
  - Total de alunos matriculados
  - Média de presença por domingo
  - Taxa de presença por turma
  - Total de ofertas
  - Total de Bíblias trazidas
  - Ranking de turmas por presença
- Comparativo entre trimestres mostra a evolução (crescimento/queda).
- O relatório nominal de frequência por aluno é restrito ao professor e secretário.

---

## 7. Integrações entre Módulos

### INT-001: Financeiro → Membros
- Dízimos são vinculados ao cadastro de membros.
- O membro pode ver seu próprio histórico de contribuições (se essa funcionalidade for habilitada).
- Ao excluir um membro, seus lançamentos financeiros são mantidos (referência permanece).

### INT-002: Patrimônio → Financeiro
- Custo de manutenção pode gerar lançamento de despesa automaticamente.
- Aquisição de bem por compra pode gerar lançamento de despesa.

### INT-003: Patrimônio → Membros
- Doadores de bens são vinculados ao cadastro de membros.
- Empréstimos de bens são feitos para membros cadastrados.

### INT-004: EBD → Membros
- Professores e alunos são membros cadastrados.
- Frequência da EBD alimenta o histórico de participação do membro.
- Visitantes recorrentes na EBD podem ser convertidos em cadastro de membro.

### INT-005: EBD → Financeiro
- Ofertas da EBD podem ser consolidadas como lançamento de receita.
- A transferência é feita pelo total do dia (não por aluno individual).

---

## 8. Validações Comuns

### Campos de Texto
| Campo | Validação |
|-------|-----------|
| Nome completo | 3-200 caracteres, apenas letras e espaços |
| E-mail | Formato RFC 5322 válido |
| Telefone | Formato: (XX) XXXXX-XXXX ou (XX) XXXX-XXXX |
| CPF | 11 dígitos, algoritmo de verificação válido |
| CEP | Formato: XXXXX-XXX |
| CNPJ | 14 dígitos, algoritmo de verificação válido |

### Campos Numéricos
| Campo | Validação |
|-------|-----------|
| Valores monetários | ≥ 0, máximo 2 casas decimais, limite: 99.999.999,99 |
| Idade | 0-150 anos |
| Percentuais | 0-100 |
| Capacidade de turma | 1-500 |

### Campos de Data
| Regra | Descrição |
|-------|-----------|
| Data de nascimento | Não pode ser futura; não pode ser > 150 anos atrás |
| Data de lançamento financeiro | Não pode ser futura (exceto despesas com vencimento) |
| Data de aula EBD | Não pode ser futura |
| Data de aquisição de bem | Não pode ser futura |
| Período de campanha | Data fim deve ser ≥ data início |

---

## 9. Glossário

| Termo | Definição |
|-------|-----------|
| **EBD** | Escola Bíblica Dominical — encontro semanal de ensino bíblico em turmas |
| **Dízimo** | Contribuição financeira de 10% da renda do membro |
| **Oferta** | Contribuição voluntária sem valor pré-definido |
| **Campanha** | Arrecadação com objetivo específico (construção, missões, etc.) |
| **Patrimônio** | Conjunto de bens pertencentes à igreja |
| **Tombamento** | Ato de registrar e numerar um bem patrimonial |
| **Depreciação** | Perda de valor do bem ao longo do tempo |
| **Inventário** | Conferência física dos bens registrados |
| **Transferência** | Saída ou entrada de membro por carta de transferência |
| **Aclamação** | Entrada de membro por aprovação em assembleia |
| **Reconciliação** | Retorno de membro que estava afastado/disciplinado |
| **Consagração** | Cerimônia de atribuição de cargo eclesiástico |
| **Multi-tenancy** | Isolamento de dados entre diferentes igrejas no mesmo sistema |
| **RBAC** | Role-Based Access Control — controle de acesso baseado em papéis |
| **Soft Delete** | Exclusão lógica (registro marcado, não apagado fisicamente) |

---

*Documento de regras de negócio — referência para validações e fluxos do sistema.*
