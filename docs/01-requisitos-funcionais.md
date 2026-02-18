# 📋 Requisitos Funcionais — Igreja Manager

## 1. Módulo de Autenticação e Autorização

### RF-AUTH-001: Login de Usuário
- **Descrição:** O sistema deve permitir que usuários se autentiquem utilizando e-mail e senha.
- **Prioridade:** Alta
- **Critérios de aceite:**
  - Campo de e-mail com validação de formato
  - Campo de senha com mínimo de 8 caracteres
  - Token JWT gerado após autenticação bem-sucedida
  - Mensagem de erro genérica para credenciais inválidas
  - Bloqueio temporário após 5 tentativas falhas consecutivas

### RF-AUTH-002: Recuperação de Senha
- **Descrição:** O sistema deve permitir a recuperação de senha através de e-mail.
- **Prioridade:** Alta
- **Critérios de aceite:**
  - Envio de link de redefinição por e-mail
  - Link com validade de 2 horas
  - Nova senha deve atender aos requisitos mínimos de segurança

### RF-AUTH-003: Controle de Permissões (RBAC)
- **Descrição:** O sistema deve implementar controle de acesso baseado em papéis (roles).
- **Prioridade:** Alta
- **Papéis padrão:**
  - **Super Admin**: Acesso total ao sistema
  - **Pastor/Líder**: Acesso a todos os módulos, com restrições em configurações
  - **Secretário(a)**: Acesso a membros e EBD
  - **Tesoureiro(a)**: Acesso ao módulo financeiro
  - **Patrimônio**: Acesso ao módulo de patrimônio
  - **Professor(a) EBD**: Acesso limitado ao módulo EBD
  - **Membro**: Acesso apenas ao próprio perfil e informações públicas

### RF-AUTH-004: Gestão Multi-Igreja
- **Descrição:** O sistema deve suportar múltiplas igrejas/congregações em uma mesma instância.
- **Prioridade:** Média
- **Critérios de aceite:**
  - Cada igreja possui seus dados isolados (multi-tenancy)
  - Um super admin pode gerenciar múltiplas igrejas
  - Dados não podem vazar entre igrejas diferentes

---

## 2. Módulo de Cadastro de Membros

### RF-MEM-001: Cadastro Completo de Membro
- **Descrição:** O sistema deve permitir o cadastro detalhado de membros da igreja.
- **Prioridade:** Alta
- **Campos obrigatórios:**
  - Nome completo
  - Data de nascimento
  - Sexo
  - Estado civil
  - Telefone principal
  - Endereço completo (CEP, logradouro, número, complemento, bairro, cidade, UF)
- **Campos opcionais:**
  - CPF
  - RG
  - E-mail
  - Telefone secundário
  - Foto de perfil
  - Profissão
  - Local de trabalho
  - Naturalidade
  - Nacionalidade
  - Escolaridade
  - Tipo sanguíneo
  - Observações

### RF-MEM-002: Informações Eclesiásticas
- **Descrição:** Registro de informações específicas da vida eclesiástica do membro.
- **Prioridade:** Alta
- **Campos:**
  - Data de conversão
  - Data de batismo nas águas
  - Data de batismo no Espírito Santo
  - Igreja de origem (se transferido)
  - Data de ingresso na igreja atual
  - Forma de ingresso (batismo, transferência, aclamação, reconciliação)
  - Cargo/função eclesiástica (pastor, presbítero, diácono, cooperador, membro)
  - Data de consagração ao cargo
  - Ministérios que participa
  - Status (ativo, inativo, transferido, desligado, falecido, visitante)

### RF-MEM-003: Gestão de Famílias
- **Descrição:** O sistema deve permitir vincular membros em grupos familiares.
- **Prioridade:** Média
- **Critérios de aceite:**
  - Criar grupo familiar com um responsável
  - Vincular cônjuge e dependentes
  - Definir grau de parentesco
  - Visualização em árvore familiar
  - Endereço compartilhado entre membros da mesma família

### RF-MEM-004: Histórico do Membro
- **Descrição:** O sistema deve manter um registro cronológico de eventos importantes do membro.
- **Prioridade:** Média
- **Eventos registráveis:**
  - Mudanças de cargo
  - Entrada e saída de ministérios
  - Transferências (entrada e saída)
  - Disciplinas eclesiásticas
  - Reconciliações
  - Batismos
  - Casamentos
  - Falecimento

### RF-MEM-005: Busca e Filtros de Membros
- **Descrição:** O sistema deve oferecer busca avançada com múltiplos filtros.
- **Prioridade:** Alta
- **Filtros disponíveis:**
  - Nome (busca parcial)
  - Status (ativo, inativo, etc.)
  - Cargo/função
  - Ministério
  - Faixa etária
  - Sexo
  - Estado civil
  - Bairro/região
  - Data de ingresso (período)
  - Aniversariantes do mês

### RF-MEM-006: Relatórios de Membros
- **Descrição:** Geração de relatórios diversos sobre os membros.
- **Prioridade:** Média
- **Relatórios:**
  - Lista geral de membros (com filtros)
  - Aniversariantes por mês
  - Estatísticas demográficas (sexo, faixa etária, estado civil)
  - Novos membros por período
  - Membros por cargo/função
  - Membros por ministério
  - Membros inativos/afastados
  - Ficha individual completa (PDF)

### RF-MEM-007: Importação e Exportação
- **Descrição:** Importar membros de planilhas e exportar dados.
- **Prioridade:** Baixa
- **Formatos:**
  - Importação: CSV, XLSX
  - Exportação: CSV, XLSX, PDF

---

## 3. Módulo de Controle Financeiro

### RF-FIN-001: Plano de Contas
- **Descrição:** Gerenciamento do plano de contas da igreja.
- **Prioridade:** Alta
- **Categorias padrão de receita:**
  - Dízimos
  - Ofertas
  - Campanhas
  - Doações
  - Eventos
  - Aluguéis
  - Outras receitas
- **Categorias padrão de despesa:**
  - Salários e benefícios
  - Aluguel do templo
  - Água, luz e telefone
  - Manutenção
  - Material de escritório
  - Material de limpeza
  - Missões
  - Ação social
  - Eventos
  - Dízimos repassados (convenção)
  - Outras despesas
- **Critérios de aceite:**
  - Categorias personalizáveis
  - Subcategorias com até 3 níveis
  - Ativar/desativar categorias sem excluir

### RF-FIN-002: Registro de Receitas
- **Descrição:** Registro de todas as entradas financeiras.
- **Prioridade:** Alta
- **Campos:**
  - Data do lançamento
  - Data de recebimento
  - Categoria (do plano de contas)
  - Valor
  - Forma de recebimento (dinheiro, PIX, transferência, cartão, cheque)
  - Membro contribuinte (opcional para ofertas, obrigatório para dízimos)
  - Descrição/observação
  - Comprovante (upload de arquivo)
  - Campanha/projeto vinculado (se aplicável)

### RF-FIN-003: Registro de Despesas
- **Descrição:** Registro de todas as saídas financeiras.
- **Prioridade:** Alta
- **Campos:**
  - Data do lançamento
  - Data de pagamento
  - Data de vencimento
  - Categoria (do plano de contas)
  - Valor
  - Forma de pagamento
  - Fornecedor/beneficiário
  - Descrição/observação
  - Nota fiscal/recibo (upload de arquivo)
  - Status (pendente, pago, cancelado)
  - Recorrente (sim/não, periodicidade)

### RF-FIN-004: Controle de Dízimos
- **Descrição:** Controle específico e detalhado dos dízimos.
- **Prioridade:** Alta
- **Critérios de aceite:**
  - Registro vinculado ao membro dizimista
  - Histórico de contribuição por membro
  - Relatório de dizimistas regulares/irregulares
  - Emissão de declaração anual de dízimos por membro
  - Controle de envelope de dízimos (numeração)
  - Sigilo total dos valores (acesso restrito ao tesoureiro)

### RF-FIN-005: Gestão de Campanhas Financeiras
- **Descrição:** Controle de campanhas e projetos específicos com meta financeira.
- **Prioridade:** Média
- **Campos:**
  - Nome da campanha
  - Descrição/objetivo
  - Meta financeira
  - Data de início e término
  - Status (ativa, encerrada, cancelada)
  - Total arrecadado (calculado)
  - Percentual atingido (calculado)

### RF-FIN-006: Conciliação e Fechamento
- **Descrição:** Controle de saldos e fechamento periódico.
- **Prioridade:** Alta
- **Critérios de aceite:**
  - Saldo atualizado em tempo real
  - Fechamento mensal com resumo
  - Não permitir edição de lançamentos após fechamento (apenas estorno)
  - Registro de quem realizou o fechamento
  - Saldo inicial configurável

### RF-FIN-007: Relatórios Financeiros
- **Descrição:** Geração de relatórios financeiros detalhados.
- **Prioridade:** Alta
- **Relatórios:**
  - Balancete mensal (receitas x despesas)
  - Demonstrativo de receitas por categoria
  - Demonstrativo de despesas por categoria
  - Fluxo de caixa
  - Relatório de dízimos por membro (restrito)
  - Relatório de campanhas (progresso e contribuintes)
  - Comparativo entre períodos
  - Gráficos de evolução financeira
  - Relatório para prestação de contas em assembleia (PDF)

### RF-FIN-008: Contas Bancárias
- **Descrição:** Gerenciamento de múltiplas contas bancárias/caixas.
- **Prioridade:** Média
- **Critérios de aceite:**
  - Cadastro de contas bancárias e caixas
  - Saldo individualizado por conta
  - Transferências entre contas
  - Conciliação bancária

---

## 4. Módulo de Gestão de Patrimônio

### RF-PAT-001: Cadastro de Bens
- **Descrição:** Registro completo dos bens patrimoniais da igreja.
- **Prioridade:** Alta
- **Campos:**
  - Código/tombamento (geração automática)
  - Descrição do bem
  - Categoria (imóvel, veículo, equipamento de som, instrumento musical, mobiliário, equipamento de informática, equipamento de cozinha, outros)
  - Subcategoria
  - Marca/modelo
  - Número de série
  - Data de aquisição
  - Valor de aquisição
  - Valor atual estimado
  - Forma de aquisição (compra, doação, construção)
  - Doador (se aplicável, vínculo com membro)
  - Nota fiscal (upload)
  - Localização/departamento
  - Estado de conservação (novo, bom, regular, ruim, inservível)
  - Fotos (múltiplas)
  - Status (ativo, em manutenção, baixado, cedido, alienado)
  - Observações

### RF-PAT-002: Controle de Depreciação
- **Descrição:** Cálculo e acompanhamento da depreciação dos bens.
- **Prioridade:** Baixa
- **Critérios de aceite:**
  - Vida útil configurável por categoria
  - Cálculo automático de depreciação (linear)
  - Valor residual
  - Relatório de depreciação acumulada

### RF-PAT-003: Manutenções e Reparos
- **Descrição:** Registro de manutenções preventivas e corretivas.
- **Prioridade:** Média
- **Campos:**
  - Bem vinculado
  - Tipo (preventiva, corretiva)
  - Data da manutenção
  - Descrição do serviço
  - Fornecedor/prestador
  - Valor
  - Próxima manutenção prevista
  - Status (agendada, em andamento, concluída)

### RF-PAT-004: Inventário
- **Descrição:** Realização e controle de inventários periódicos.
- **Prioridade:** Média
- **Critérios de aceite:**
  - Criação de inventário com data
  - Checklist de bens por localização
  - Registro de conferência (encontrado, não encontrado, divergência)
  - Relatório de divergências
  - Histórico de inventários

### RF-PAT-005: Empréstimo de Bens
- **Descrição:** Controle de empréstimo de equipamentos e bens.
- **Prioridade:** Baixa
- **Campos:**
  - Bem emprestado
  - Responsável pelo empréstimo (membro)
  - Data de saída
  - Data prevista de devolução
  - Data efetiva de devolução
  - Estado na saída
  - Estado na devolução
  - Observações
  - Termo de responsabilidade (geração automática)

### RF-PAT-006: Relatórios de Patrimônio
- **Descrição:** Geração de relatórios patrimoniais.
- **Prioridade:** Média
- **Relatórios:**
  - Inventário geral (todos os bens)
  - Bens por categoria
  - Bens por localização
  - Bens por estado de conservação
  - Histórico de manutenções
  - Bens emprestados
  - Bens baixados
  - Valor total do patrimônio
  - Relatório de depreciação

---

## 5. Módulo EBD (Escola Bíblica Dominical)

### RF-EBD-001: Cadastro de Turmas
- **Descrição:** Gerenciamento das turmas da EBD.
- **Prioridade:** Alta
- **Campos:**
  - Nome da turma
  - Faixa etária (de/até)
  - Sala/local
  - Capacidade máxima
  - Trimestre/período letivo
  - Professor(a) titular
  - Professor(a) auxiliar
  - Status (ativa, inativa)

### RF-EBD-002: Gestão de Professores
- **Descrição:** Cadastro e acompanhamento de professores da EBD.
- **Prioridade:** Alta
- **Critérios de aceite:**
  - Vinculação com cadastro de membro
  - Histórico de turmas lecionadas
  - Disponibilidade por período
  - Certificações/capacitações
  - Avaliação de desempenho (presença como professor)

### RF-EBD-003: Matrícula de Alunos
- **Descrição:** Matrícula de alunos nas turmas da EBD.
- **Prioridade:** Alta
- **Critérios de aceite:**
  - Vinculação com cadastro de membro (ou visitante)
  - Um aluno por turma por período
  - Transferência entre turmas
  - Histórico de turmas frequentadas
  - Controle de lotação da turma

### RF-EBD-004: Controle de Frequência
- **Descrição:** Registro de presença dos alunos e professores por aula.
- **Prioridade:** Alta
- **Critérios de aceite:**
  - Chamada por turma e data
  - Status: presente, ausente, justificado
  - Registro de visitantes na aula
  - Observações por aluno
  - Quem registrou a chamada
  - Registro de Bíblia trazida (sim/não)
  - Registro de revista/material trazido (sim/não)
  - Registro de oferta da EBD

### RF-EBD-005: Registro de Aulas/Lições
- **Descrição:** Controle das lições ministradas.
- **Prioridade:** Média
- **Campos:**
  - Data da aula
  - Turma
  - Professor que ministrou
  - Número da lição (da revista)
  - Título da lição
  - Tema/assunto
  - Texto bíblico base
  - Resumo/anotações
  - Material utilizado

### RF-EBD-006: Relatórios da EBD
- **Descrição:** Geração de relatórios da Escola Bíblica Dominical.
- **Prioridade:** Alta
- **Relatórios:**
  - Frequência por turma (diária, mensal, trimestral)
  - Frequência por aluno
  - Percentual de presença por turma
  - Ranking de turmas (presença)
  - Alunos faltosos (ausências consecutivas)
  - Estatísticas gerais da EBD (total de alunos, média de presença)
  - Número de Bíblias e revistas por turma
  - Ofertas da EBD por período
  - Relatório consolidado trimestral
  - Comparativo entre trimestres

### RF-EBD-007: Calendário da EBD
- **Descrição:** Calendário de atividades da EBD.
- **Prioridade:** Baixa
- **Critérios de aceite:**
  - Visualização em calendário
  - Registro de aulas normais
  - Registro de aulas especiais/eventos
  - Feriados e datas sem EBD
  - Períodos de férias

---

## 6. Funcionalidades Gerais

### RF-GER-001: Dashboard
- **Descrição:** Tela principal com indicadores e resumos.
- **Prioridade:** Alta
- **Indicadores:**
  - Total de membros ativos
  - Novos membros no mês
  - Aniversariantes da semana
  - Saldo financeiro atual
  - Receitas e despesas do mês
  - Presença na última EBD
  - Próximos eventos
  - Alertas (despesas vencidas, inventários pendentes, etc.)

### RF-GER-002: Notificações
- **Descrição:** Sistema de notificações e alertas.
- **Prioridade:** Baixa
- **Tipos:**
  - Aniversariantes do dia
  - Despesas a vencer
  - Manutenções agendadas
  - Devoluções de empréstimos pendentes
  - Alertas configuráveis

### RF-GER-003: Configurações do Sistema
- **Descrição:** Configurações gerais personalizáveis.
- **Prioridade:** Média
- **Configurações:**
  - Dados da igreja (nome, CNPJ, endereço, logo)
  - Configuração de e-mail (SMTP)
  - Personalização de campos obrigatórios
  - Backup de dados
  - Logs de auditoria (quem fez o quê e quando)

### RF-GER-004: Logs e Auditoria
- **Descrição:** Registro de todas as ações relevantes no sistema.
- **Prioridade:** Média
- **Critérios de aceite:**
  - Registro de criação, edição e exclusão de registros
  - Identificação do usuário responsável
  - Data e hora da ação
  - Valores anteriores e novos (para edições)
  - Consulta com filtros por data, usuário e módulo
  - Dados de auditoria não podem ser alterados ou excluídos

---

## Requisitos Não Funcionais

### RNF-001: Performance
- Tempo de resposta da API: máximo 500ms para consultas simples
- Tempo de carregamento da interface: máximo 3 segundos
- Suporte a pelo menos 100 usuários simultâneos

### RNF-002: Segurança
- Senhas armazenadas com hash bcrypt/argon2
- Comunicação via HTTPS (TLS 1.3)
- Tokens JWT com expiração configurável
- Rate limiting na API
- Validação de inputs (proteção contra SQL injection, XSS)
- CORS configurável
- Dados sensíveis (financeiros) com acesso restrito

### RNF-003: Disponibilidade
- Uptime mínimo de 99.5%
- Backup automático diário do banco de dados
- Estratégia de disaster recovery documentada

### RNF-004: Usabilidade
- Interface responsiva para todos os tamanhos de tela
- Suporte offline para funcionalidades essenciais (frequência EBD)
- Tema claro e escuro
- Acessibilidade (WCAG 2.1 nível AA)

### RNF-005: Escalabilidade
- Arquitetura preparada para crescimento horizontal
- Paginação em todas as listagens
- Cache de consultas frequentes

### RNF-006: Manutenibilidade
- Cobertura mínima de testes: 80%
- Documentação da API (OpenAPI/Swagger)
- Logs estruturados (JSON)
- Código seguindo padrões e linters configurados

---

*Documento vivo — atualizado conforme novas funcionalidades forem definidas.*
