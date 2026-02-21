-- ============================================================================
-- Seed: Membros e Congregações — AD Ministério de Tutóia
-- Data: 20/02/2026
-- Descrição: Popula o banco com os membros reais da igreja e suas congregações.
--            Seguro para re-execução (verifica se já existe dados).
-- ============================================================================

DO $$
DECLARE
  v_church_id UUID;
  v_sede_id UUID;
  v_paxica_id UUID;
  v_comum_id UUID;
  v_nova_terra_id UUID;
  v_residencial_id UUID;
  v_member_count INT;
  v_leader_id UUID;
BEGIN
  -- ==========================================
  -- 0. Obter church_id
  -- ==========================================
  SELECT id INTO v_church_id FROM churches LIMIT 1;

  IF v_church_id IS NULL THEN
    RAISE EXCEPTION 'Nenhuma igreja encontrada. Execute o app primeiro para criar os dados iniciais.';
  END IF;

  -- Atualizar nome da igreja para refletir a realidade
  UPDATE churches SET
    name = 'AD Ministério de Tutóia',
    denomination = 'Assembleia de Deus',
    pastor_name = 'Pr. Daniel Xavier Silva',
    city = 'Tutóia',
    state = 'MA'
  WHERE id = v_church_id;

  -- ==========================================
  -- 1. Verificar se já existem membros
  -- ==========================================
  SELECT COUNT(*) INTO v_member_count FROM members WHERE church_id = v_church_id;

  IF v_member_count > 0 THEN
    RAISE NOTICE 'Membros já existem (%), pulando seed', v_member_count;
    RETURN;
  END IF;

  RAISE NOTICE 'Nenhum membro encontrado — criando congregações e membros...';

  -- ==========================================
  -- 2. Criar Congregações
  -- ==========================================

  INSERT INTO congregations (church_id, name, short_name, type, city, state, sort_order)
  VALUES (v_church_id, 'Sede - Templo Central', 'Sede', 'sede', 'Tutóia', 'MA', 0)
  RETURNING id INTO v_sede_id;

  INSERT INTO congregations (church_id, name, short_name, type, city, state, sort_order)
  VALUES (v_church_id, 'Congregação IDS Paxicá', 'Paxicá', 'congregacao', 'Tutóia', 'MA', 1)
  RETURNING id INTO v_paxica_id;

  INSERT INTO congregations (church_id, name, short_name, type, city, state, sort_order)
  VALUES (v_church_id, 'Congregação IDS Comum', 'Comum', 'congregacao', 'Tutóia', 'MA', 2)
  RETURNING id INTO v_comum_id;

  INSERT INTO congregations (church_id, name, short_name, type, city, state, sort_order)
  VALUES (v_church_id, 'Congregação IDS Nova Terra', 'Nova Terra', 'congregacao', 'Tutóia', 'MA', 3)
  RETURNING id INTO v_nova_terra_id;

  INSERT INTO congregations (church_id, name, short_name, type, city, state, sort_order)
  VALUES (v_church_id, 'Congregação IDS Residencial', 'Residencial', 'congregacao', 'Tutóia', 'MA', 4)
  RETURNING id INTO v_residencial_id;

  RAISE NOTICE 'Congregações criadas: Sede=%, Paxicá=%, Comum=%, Nova Terra=%, Residencial=%',
    v_sede_id, v_paxica_id, v_comum_id, v_nova_terra_id, v_residencial_id;

  -- ==========================================
  -- 3. SEDE — Membros Batizados (66)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, water_baptism_date, phone_primary, status, role_position, entry_type, city, state, nationality) VALUES
  (v_church_id, v_sede_id, 'Albertina Araújo', 'feminino', '1975-09-01', '2010-02-14', '(98) 98856-5344', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Antonio Daniel de Lima do Nascimento', 'masculino', '1971-07-23', NULL, '(98) 98918-5719', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Amanda Paula da Silva', 'feminino', '1983-01-28', '2000-09-17', '(98) 98817-6974', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Ana Cláudia Furtado Brasil', 'feminino', '1976-09-20', '2000-08-14', '(98) 98752-1969', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Arthur Pontes da Fonseca', 'masculino', '1982-11-24', '2010-02-20', '(98) 99965-6819', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Bernardo Rodrigues Araújo', 'masculino', '1977-11-13', '2025-12-07', '(98) 98504-8666', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Bruno Loureiro Bossi de Oliveira', 'masculino', '1979-05-12', '1998-01-07', '(98) 98895-3170', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Cristhiane Macedo Silva do Nascimento', 'feminino', '1988-09-09', '2024-10-20', '(98) 98493-2133', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Claudiana de Sousa Oliveira Silva', 'feminino', '1985-07-21', '2003-11-13', '(98) 98574-1647', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Clemilda Conceição de Sales', 'feminino', '1989-07-22', '2020-09-13', '(98) 98895-2372', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Clara Maria Caldas de Lima', 'feminino', '1968-09-04', '2015-12-13', '(98) 98562-3740', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Daniel Xavier Silva', 'masculino', '1988-05-30', '2003-03-03', '(98) 99975-4560', 'ativo', 'pastor', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Daniel Ferreira de Sousa', 'masculino', '1989-04-03', '2003-10-26', '(98) 98444-7394', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Darlene Glória Oliveira dos Santos', 'feminino', '1970-09-12', '1987-08-08', '(98) 98489-4393', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Denilson de Sousa Carvalho', 'masculino', '1987-06-02', '2022-11-12', '(98) 98875-5387', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Diogo Carvalho França', 'masculino', '1986-04-25', '2003-09-28', '(98) 98152-6823', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Edivar Divino Nascimento', 'masculino', '1970-12-28', '2007-08-18', '(98) 98485-0991', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Elizanete Ribeiro Sousa', 'feminino', '1975-08-29', '2012-01-04', '(98) 98492-4881', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Elinete Brito Rocha de Sousa', 'feminino', '1988-08-16', '2010-10-07', '(98) 97001-5079', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Eliziane Coelho da Silva', 'feminino', '1985-02-13', '2014-12-07', '(98) 98542-0973', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Edson Ismael Sousa de Oliveira', 'masculino', '2010-10-03', '2021-10-24', '(98) 98719-8178', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Enzo Aristides Caldas Belo', 'masculino', '2013-07-23', '2025-12-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Fabiana de Oliveira Silva', 'feminino', '1987-05-14', '2005-09-25', '(98) 98789-7306', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Filipe de Oliveira Pontes da Fonseca', 'masculino', '2011-11-26', '2025-12-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Gerlane Cristina da S. Bossi de Oliveira', 'feminino', '1988-01-25', '2008-01-07', '(21) 98895-2406', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Glauco Peter Silva Pessoa', 'masculino', '1984-08-24', NULL, '(98) 8875-0006', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Isabelle Lorrane Sousa de Oliveira', 'feminino', '2009-08-23', '2021-10-24', '(98) 98719-4018', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Idiléia Patrício Lira', 'feminino', '1981-05-15', '1996-07-04', '(98) 98906-6754', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Isaurina da Silva Nascimento', 'feminino', '1979-08-01', '2007-08-18', '(98) 98913-5377', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Jamile Mendes de Lima', 'feminino', '2009-06-11', NULL, '(98) 98499-9215', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Jeilson Barroso Silva', 'masculino', '1993-03-13', '2011-06-18', '(86) 99973-6756', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Jefherson Ramon Bezerra Belo', 'masculino', '1988-11-12', NULL, '(98) 98825-6877', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'João Rodolfo Pessoa Neto', 'masculino', '1961-04-14', NULL, '(98) 98243-9129', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Joele Fernandes Pessoa', 'masculino', '1988-01-21', '1999-04-22', '(98) 97003-3384', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Jorge Maurício Pereira Veras', 'masculino', '1976-11-02', '2021-10-24', '(98) 98506-6890', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Jordania de Oliveira Conceição Fonseca', 'feminino', '1988-01-15', '2009-11-20', '(98) 98893-6337', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'José Francisco Silva Fonseca', 'masculino', '1963-04-07', '2005-08-22', '(98) 98595-3709', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Juliana Caldas de Lima Belo', 'feminino', '1993-05-14', '2012-03-20', '(98) 98701-3766', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Jakeline Sousa Araujo e Silva', 'feminino', '1994-12-10', '2009-01-15', '(98) 98346-9180', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Larissa Emanoelle de Oliveira Santos', 'feminino', '2012-09-26', '2025-12-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Lucas Henrick Martins Soares', 'masculino', '2014-11-01', '2025-12-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Lurdicilea Silva Gomes', 'feminino', NULL, NULL, '(98) 99966-4646', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Maina Leane Rocha Rêgo', 'feminino', '1992-05-07', '2024-10-20', '(98) 98438-6640', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Margarete dos Santos', 'feminino', '1971-05-04', '1991-07-06', '(98) 98565-1399', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Maria Eva de Lima', 'feminino', '1971-03-18', '2005-09-29', '(98) 98918-5719', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Maria de Lurdes Gomes Pereira', 'feminino', '1962-03-06', '1977-01-11', '(98) 98553-7651', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Maria Ivanilda da Silva', 'feminino', '1962-12-09', '2010-02-14', '(98) 98445-2153', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Maria de Sousa Oliveira', 'feminino', '1946-07-03', NULL, '(98) 98464-9755', 'ativo', 'membro', NULL, 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Marina de Moura Lima Neta', 'feminino', '1969-08-29', NULL, '(98) 98430-8061', 'ativo', 'membro', NULL, 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Maura Oliveira da Rocha', 'feminino', '1995-07-18', NULL, '(98) 98624-8154', 'ativo', 'membro', NULL, 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Maria da Conceição Oliveira de Carvalho', 'feminino', '1968-02-19', '2006-07-08', '(98) 98473-2633', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Maria de Nazaré Martins de Sousa', 'feminino', '1971-09-08', '2025-12-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Nicole de Oliveira Pontes da Fonseca', 'feminino', '2013-02-13', '2025-12-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Nilcimar de Queiroz Belo', 'feminino', '1964-12-18', '2000-01-11', '(98) 98504-0695', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Nathalie Araujo Almeida Caldas Castro', 'feminino', '1987-02-08', '2011-09-10', '(98) 98179-6533', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Orlenio de Jesus Matos Araújo', 'masculino', '1979-05-02', NULL, '(98) 98912-6836', 'ativo', 'membro', NULL, 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Pedro Silva de Lima', 'masculino', '1968-06-20', '2015-12-13', '(98) 98479-3582', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Raimundo Alves dos Santos', 'masculino', '1967-06-29', '2005-09-29', '(98) 98465-5521', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Raimunda dos Santos Jacinto de Oliveira', 'feminino', '1987-10-26', '2019-06-16', '(98) 98877-5337', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Romênia Castro de Lima França', 'feminino', '1986-08-15', NULL, '(98) 99170-0351', 'ativo', 'membro', NULL, 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Renata Marjourie dos Santos', 'feminino', '1982-08-15', NULL, '(86) 99596-5950', 'ativo', 'membro', NULL, 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Silveline Maria da Silva Martins', 'feminino', '1991-10-17', '2012-06-16', '(98) 98455-2906', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Samara Célia Vale', 'feminino', '1988-02-18', '2019-06-16', '(98) 98565-2927', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Tiago Oliveira dos Santos', 'masculino', '1990-07-08', '2003-03-03', '(98) 98536-7360', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Valquiria Valéria Alves Viana', 'feminino', '1986-06-09', '2002-05-30', '(98) 98440-0992', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Waldeian Macedo Silva', 'masculino', '1984-04-23', '2014-12-07', '(98) 98738-7081', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 4. SEDE — Congregados (17)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, status, role_position, city, state, nationality) VALUES
  (v_church_id, v_sede_id, 'Arthur Pessoa Silva', 'masculino', '2015-01-23', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Camila Macedo Sousa', 'feminino', '2009-01-19', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Charles Viana de Paulo', 'masculino', '1980-07-25', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Dvison Juan de Sousa Sales', 'masculino', '2013-09-03', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Davi Luiz Soares Rocha', 'masculino', '2012-09-15', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Ester Vitória Rocha de Sousa', 'feminino', '2015-04-14', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Emilly de Sousa Sales', 'feminino', '2015-08-28', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Isabele Luiz dos Santos', 'feminino', '2012-09-10', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'João Vitor Ferreira da Silva', 'masculino', '2011-10-26', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'José Sousa Rêgo', 'masculino', '1979-10-24', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Jorgeana Gomes da Silva', 'feminino', '1989-01-21', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Kaylane Yujulle Oliveira Silva', 'feminino', '2003-12-25', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Luiz Eduardo da Silva Ferreira', 'masculino', '2012-10-29', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Otávio Luiz Araujo e Silva', 'masculino', '1998-10-21', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Pedro Emanuel M.S. do Nascimento', 'masculino', '2013-03-07', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Roniela Pereira da Silva', 'feminino', '1986-07-20', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Vitor Daniel de Lima Galvão', 'masculino', '2009-04-21', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 5. SEDE — Crianças (13)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, status, role_position, city, state, nationality) VALUES
  -- Crianças 6-9 anos
  (v_church_id, v_sede_id, 'Anabela Caldas Belo', 'feminino', '2018-04-20', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Anna Clara Oliveira Silva', 'feminino', '2018-11-11', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Ângelo Riquelme de Jesus Oliveira Silva', 'masculino', '2017-08-15', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Isadora de Oliveira Santos', 'feminino', '2018-10-23', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Marina de Oliveira Pontes da Fonseca', 'feminino', '2017-12-21', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Miguel Castro de Lima França', 'masculino', '2016-08-12', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Liz Maria Oliveira Braga', 'feminino', '2018-10-14', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  -- Crianças 2-5 anos
  (v_church_id, v_sede_id, 'Carolina Oliveira Rocha', 'feminino', '2020-06-24', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Dália Vitória Rocha de Sousa', 'feminino', '2020-10-07', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Kalel Araujo Almeida Caldas Castro', 'masculino', '2023-11-01', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Theo Castro de Lima França', 'masculino', '2022-11-30', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_sede_id, 'Théo Helnatan Rocha', 'masculino', '2023-02-10', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  -- Crianças 0-1 ano
  (v_church_id, v_sede_id, 'Joana Rocha Rêgo', 'feminino', '2025-09-28', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 6. PAXICÁ — Membros Batizados (22)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, water_baptism_date, phone_primary, status, role_position, entry_type, city, state, nationality) VALUES
  (v_church_id, v_paxica_id, 'Adriel Silva Barroso', 'masculino', '2012-09-20', '2025-12-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Bernardo Demétrio Silva', 'masculino', '1966-04-19', '2001-01-07', '(98) 98879-0548', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Cleydiomar Lima Pereira', 'feminino', '1979-05-28', NULL, NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Ernane Sousa do Nascimento', 'masculino', '1982-07-06', '2001-01-07', NULL, 'ativo', 'presbitero', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Eliene Pereira', 'feminino', '1977-11-08', NULL, NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Fernanda Silva Nascimento de Albuquerque', 'feminino', '2004-07-04', '2018-06-30', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Gabriela Silva Nascimento', 'feminino', '2007-09-24', '2018-07-17', '(98) 98542-8320', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Gabriel Silva Barroso', 'masculino', '2011-05-15', '2025-12-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Gilvan Carvalho Barroso', 'masculino', '1985-11-26', '2020-03-29', '(98) 98757-7539', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Gilvan Santos do Carmo', 'masculino', '1973-11-15', '2016-11-02', '(98) 97011-4806', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Gilberto de Mello Guerra', 'masculino', '1957-02-01', '1985-10-16', '(98) 98503-2118', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Guilherme Vieira de Albuquerque', 'masculino', '2004-01-16', '2021-07-25', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Gustavo Pereira Lima', 'masculino', '2007-08-13', '2025-05-25', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Keliane Silva Cardoso', 'feminino', '2007-01-13', '2025-05-25', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Leandro Gomes Feitosa', 'masculino', '1985-04-07', '2020-03-29', '(98) 98400-8625', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Lucilene Carvalho Barroso', 'feminino', '1991-08-18', '2020-03-29', '(98) 98912-7662', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Maria Helena Lima Silva', 'feminino', '1984-07-23', '2018-06-30', '(98) 98879-0548', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Maria do Socorro Pereira do Nascimento', 'feminino', '1977-01-11', '2016-11-02', '(98) 99214-2023', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Maria Clevis Soares Diniz', 'feminino', '1943-01-26', '1998-05-17', '(98) 99221-6264', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Matheus Pereira Lima', 'masculino', '2002-10-05', NULL, NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Minelvina Lopes da Silva', 'feminino', '1995-06-21', '2020-03-29', '(98) 98907-4019', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Rosena da Silva Oliveira Nascimento', 'feminino', '1979-05-08', '2001-01-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 7. PAXICÁ — Crianças e Congregados (3)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, phone_primary, status, role_position, city, state, nationality) VALUES
  (v_church_id, v_paxica_id, 'Emilly Nascimento de Albuquerque', 'feminino', '2025-10-22', NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Luana Barroso Feitosa', 'feminino', '2021-04-12', NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_paxica_id, 'Gracilene Loiola Assunção', 'feminino', '1978-08-16', NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 8. COMUM — Membros Batizados (25)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, water_baptism_date, phone_primary, status, role_position, entry_type, city, state, nationality) VALUES
  (v_church_id, v_comum_id, 'Ana Paula de Freitas Souza', 'feminino', '1993-06-30', '2006-06-18', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Ariel Costa de Freitas', 'masculino', '1995-04-21', '2012-06-15', '(98) 98535-4905', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Antônio Gomes Araújo', 'masculino', '1966-02-28', '2018-06-30', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Arthur Silva Araújo', 'masculino', '2012-03-20', '2023-12-01', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Bruno Ramos Araújo', 'masculino', '2012-09-19', '2025-05-25', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Cintionayra Santos Moraes', 'feminino', '1996-07-22', '2022-05-27', '(98) 98913-0636', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Cleudiane Silva dos Santos', 'feminino', '1983-12-16', '2024-10-20', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Francisca Rocha da Silva', 'feminino', '1989-11-06', '2018-06-30', '(98) 98573-0690', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Francisca Daniele da Silva Costa', 'feminino', '1999-05-30', '2017-12-17', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Henrique Costa Santos', 'masculino', '2010-11-05', '2023-08-27', '(98) 98496-4593', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Luzinete de Oliveira Silva', 'feminino', '1970-05-27', '2022-05-27', '(98) 98583-7774', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Lucilene Araújo dos Santos', 'feminino', '1983-07-04', '2022-05-27', '(98) 98580-6533', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Luzite Costa da Silva', 'feminino', '1965-12-02', '2021-06-13', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Maria do Rosário Costa de Freitas', 'feminino', '1970-08-14', '1996-07-08', '(98) 98850-5047', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Maria Antônia Costa', 'feminino', '1952-03-23', NULL, '(98) 99614-2593', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Mariana Ramos Oliveira', 'feminino', '2009-11-07', '2025-05-25', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Maria de Fátima Sousa Ramos', 'feminino', '1989-05-13', '2025-05-25', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Osinaldo da Costa Macedo', 'masculino', '1988-04-28', '2023-08-27', '(98) 99971-5902', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Osivan Rocha Macedo', 'masculino', '2009-07-04', '2025-05-25', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Rosemeire Sousa Ramos de Freitas', 'feminino', '1974-11-01', '2012-06-15', '(98) 98720-6027', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Rosenilda Costa de Freitas', 'feminino', '1978-06-02', NULL, '(98) 98907-7512', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Romário Rocha da Costa', 'masculino', '1991-10-12', '2015-01-02', NULL, 'ativo', 'presbitero', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Roseli de Sousa Freitas Caldas', 'feminino', '2003-03-25', NULL, NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Vanúsia Rocha da Costa', 'feminino', '1987-08-11', '2023-08-27', '(98) 98826-4064', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Viviane Costa da Silva', 'feminino', '1984-01-29', '2014-08-22', '(98) 98908-5901', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 9. COMUM — Congregados adultos (3)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, phone_primary, status, role_position, city, state, nationality) VALUES
  (v_church_id, v_comum_id, 'Israel da Conceição Caldas Freitas', 'masculino', '1998-10-28', NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Carminha', 'feminino', NULL, NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Cibele', 'feminino', NULL, NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 10. COMUM — Crianças 6-11 anos (16)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, status, role_position, city, state, nationality) VALUES
  (v_church_id, v_comum_id, 'Ana Rita Costa Santos', 'feminino', '2019-01-09', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Ana Cristina Rocha da Hora', 'feminino', '2015-03-14', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Ana Cecília', 'feminino', NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Elias Costa de Freitas Góes', 'masculino', '2018-05-20', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Jardson Ferreira Costa', 'masculino', '2015-11-27', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Jamilly Ferreira Costa', 'feminino', '2018-03-30', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Luana Cristina Silva Araújo', 'feminino', '2019-08-24', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Lorenzo de Jesus Freitas da Rocha', 'masculino', '2017-02-17', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Lavinny Freitas Veras Porto', 'feminino', '2018-09-28', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Melissa Manoela Veras da Rocha', 'feminino', '2017-07-29', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Maria Vitória Rocha da Paz', 'feminino', '2014-09-10', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Maria Eduarda Rocha Reis', 'feminino', '2017-08-30', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Maria Isabel', 'feminino', NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Osivânia Rocha Macedo', 'feminino', '2017-07-31', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Vitória Beatriz Sousa Luz', 'feminino', '2016-08-05', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Victor Hugo Sousa Luz', 'masculino', '2015-04-10', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 11. COMUM — Crianças 3-5 anos (6)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, status, role_position, city, state, nationality) VALUES
  (v_church_id, v_comum_id, 'Arthur Costa Freitas', 'masculino', '2021-05-13', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Gael da Hora Ferreira', 'masculino', '2022-01-07', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Isabela Veras da Rocha', 'feminino', '2021-05-26', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Maria Luíza Sousa da Silva', 'feminino', '2022-02-20', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Samili Vitória Freitas Olimpil', 'feminino', '2020-06-12', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_comum_id, 'Sara Vitória Silva Araújo', 'feminino', '2021-03-07', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 12. COMUM — Crianças 0-2 anos (1)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, status, role_position, city, state, nationality) VALUES
  (v_church_id, v_comum_id, 'Heitor Costa Santos', 'masculino', '2025-12-27', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 13. NOVA TERRA — Membros Batizados (21)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, water_baptism_date, phone_primary, status, role_position, entry_type, city, state, nationality) VALUES
  (v_church_id, v_nova_terra_id, 'Aldinéia Sousa Marques', 'feminino', '1976-11-12', '1991-07-07', '(98) 99708-9225', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Auricélia Sousa do Nascimento', 'feminino', '1993-08-11', NULL, NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Arnaldo Sousa do Nascimento', 'masculino', '1980-11-03', '2013-07-17', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Antônio dos Santos', 'masculino', '1971-11-25', '2025-05-25', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Bernardo Pereira do Nascimento', 'masculino', '1949-07-11', '1991-07-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Djanira Sousa do Nascimento', 'feminino', '1955-07-15', '1991-07-07', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Deuzanira Sousa do Nascimento', 'feminino', '1984-11-21', '1999-05-11', '(98) 97011-4029', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Edson Viana de Sousa', 'masculino', '1987-08-06', '2013-09-15', '(98) 98714-5879', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Érica Karolina Conceição Sousa', 'feminino', '1994-01-03', '2013-09-15', '(98) 99607-0650', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Edicléia Silva de Oliveira', 'feminino', '1973-08-08', NULL, NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'José Rosado Marques', 'masculino', '1974-08-21', '1992-08-07', '(98) 99967-6720', 'ativo', 'presbitero', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Kalebe Sousa Marques', 'masculino', '2004-08-31', '2016-10-02', '(98) 99246-1921', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Luiz Carlos Gomes da Costa', 'masculino', '1962-09-05', NULL, NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Maria Vitória da Silva Reis', 'feminino', '2002-06-30', '2016-10-02', '(98) 98467-5467', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Maysa Sousa Marques', 'feminino', '2009-02-24', '2021-10-24', '(98) 98521-7500', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Maria de Lurdes Pereira da Silva', 'feminino', '1950-07-20', '2019-10-30', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Maria das Neves Pereira Diniz', 'feminino', '1959-08-03', '2013-09-15', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Maria do Espírito Santo da Costa', 'feminino', '1985-04-14', NULL, NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Raimunda Nonata Silva da Costa', 'feminino', '1982-09-11', '2016-10-02', '(98) 98492-5888', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Rodrigo Diniz Figueiras', 'masculino', '1995-01-14', '2013-09-15', NULL, 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Suelize Ilarindo Bezerra', 'feminino', '1967-06-05', '1998-12-06', '(98) 98844-3150', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 14. NOVA TERRA — Não batizados (2)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, phone_primary, status, role_position, city, state, nationality) VALUES
  (v_church_id, v_nova_terra_id, 'Lucas Sousa Daufenbach', 'masculino', '2020-07-07', NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_nova_terra_id, 'Denilson Sousa Silva', 'masculino', '1998-04-27', NULL, 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 15. RESIDENCIAL — Membros Batizados (14)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, water_baptism_date, phone_primary, status, role_position, entry_type, city, state, nationality) VALUES
  (v_church_id, v_residencial_id, 'Adriel Gonçalves Oliveira', 'masculino', '2002-10-16', '2015-12-27', '(98) 98543-9104', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Camilo da Silva Oliveira', 'masculino', '1977-08-10', '1999-05-16', '(98) 99852-8829', 'ativo', 'presbitero', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Carmem Thaís Lisboa de Menezes', 'feminino', '1990-03-03', '2025-10-11', '(98) 98553-6368', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Carmem Lisboa de Menezes', 'feminino', '1936-03-22', '2025-05-24', '(98) 98553-6368', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Carmem Lúcia Lisboa de Menezes', 'feminino', '1972-03-08', '2024-10-20', '(98) 98553-6368', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Dalila da Silva Gonçalves', 'feminino', '1961-07-15', '1979-03-18', '(98) 98736-1813', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Daniele Nascimento da Silva', 'feminino', '1995-01-16', '2024-10-20', '(98) 98582-9707', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Francilene Gonçalves da Silva', 'feminino', '2006-03-28', '2015-12-27', '(98) 98493-1865', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'José Arnaldo Gonçalves', 'masculino', '1955-07-16', '1979-03-18', '(98) 98736-1813', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Jataniel Gonçalves Oliveira', 'masculino', '2003-10-10', '2015-12-27', '(98) 98571-0141', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Jerciara Gonçalves da Silva', 'feminino', '2005-01-09', '2024-10-20', '(98) 99966-2952', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Maria Arnalda Gonçalves Oliveira', 'feminino', '1981-07-25', '1999-05-16', '(98) 97010-4718', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Miliane Gonçalves de Oliveira', 'feminino', '2000-11-20', '2015-12-27', '(98) 98801-9500', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)'),
  (v_church_id, v_residencial_id, 'Samuel Lima da Silva', 'masculino', '2006-04-30', '2024-10-20', '(98) 98403-9936', 'ativo', 'membro', 'batismo', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 16. RESIDENCIAL — Não batizado (1)
  -- ==========================================
  INSERT INTO members (church_id, congregation_id, full_name, gender, birth_date, phone_primary, status, role_position, city, state, nationality) VALUES
  (v_church_id, v_residencial_id, 'Wenderson da Silva Imazú', 'masculino', '2013-04-10', '(98) 98582-9707', 'congregado', 'congregado', 'Tutóia', 'MA', 'Brasileiro(a)');

  -- ==========================================
  -- 17. Atualizar líderes das congregações
  -- ==========================================

  -- Sede: Pastor Daniel Xavier Silva
  SELECT id INTO v_leader_id FROM members
    WHERE full_name = 'Daniel Xavier Silva' AND church_id = v_church_id LIMIT 1;
  IF v_leader_id IS NOT NULL THEN
    UPDATE congregations SET leader_id = v_leader_id WHERE id = v_sede_id;
  END IF;

  -- Paxicá: Ernane Sousa do Nascimento
  SELECT id INTO v_leader_id FROM members
    WHERE full_name = 'Ernane Sousa do Nascimento' AND church_id = v_church_id LIMIT 1;
  IF v_leader_id IS NOT NULL THEN
    UPDATE congregations SET leader_id = v_leader_id WHERE id = v_paxica_id;
  END IF;

  -- Comum: Romário Rocha da Costa
  SELECT id INTO v_leader_id FROM members
    WHERE full_name = 'Romário Rocha da Costa' AND church_id = v_church_id LIMIT 1;
  IF v_leader_id IS NOT NULL THEN
    UPDATE congregations SET leader_id = v_leader_id WHERE id = v_comum_id;
  END IF;

  -- Nova Terra: José Rosado Marques
  SELECT id INTO v_leader_id FROM members
    WHERE full_name = 'José Rosado Marques' AND church_id = v_church_id LIMIT 1;
  IF v_leader_id IS NOT NULL THEN
    UPDATE congregations SET leader_id = v_leader_id WHERE id = v_nova_terra_id;
  END IF;

  -- Residencial: Camilo da Silva Oliveira
  SELECT id INTO v_leader_id FROM members
    WHERE full_name = 'Camilo da Silva Oliveira' AND church_id = v_church_id LIMIT 1;
  IF v_leader_id IS NOT NULL THEN
    UPDATE congregations SET leader_id = v_leader_id WHERE id = v_residencial_id;
  END IF;

  -- ==========================================
  -- 18. Resumo final
  -- ==========================================
  RAISE NOTICE '✅ Seed concluído com sucesso!';
  RAISE NOTICE '   Sede: 96 membros (66 batizados + 17 congregados + 13 crianças)';
  RAISE NOTICE '   Paxicá: 25 membros (22 batizados + 3 congregados/crianças)';
  RAISE NOTICE '   Comum: 51 membros (25 batizados + 3 congregados + 23 crianças)';
  RAISE NOTICE '   Nova Terra: 23 membros (21 batizados + 2 não batizados)';
  RAISE NOTICE '   Residencial: 15 membros (14 batizados + 1 não batizado)';
  RAISE NOTICE '   Total: 210 membros, 5 congregações';

END $$;
