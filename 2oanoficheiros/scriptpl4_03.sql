CREATE TRIGGER BonificarUsers
ON reserva
AFTER UPDATE
AS
BEGIN
    PRINT 'Trigger de bonificação de utilizadores ativado.';
    -- Variáveis locais
    DECLARE @id_utilizador NVARCHAR(20);
    DECLARE @prioridade_corrente INT;
    DECLARE @limite_prioridade INT;
    -- Obter utilizadores com duas ou mais reservas satisfeitas
    DECLARE SatisfiedUsers CURSOR FOR
    SELECT r.id_utilizador
    FROM reserva r
    WHERE r.estado_reserva = 'satisfied'
    GROUP BY r.id_utilizador
    HAVING COUNT(*) >= 2; -- Reservas satisfeitas necessárias para bonificação
    OPEN SatisfiedUsers;
    FETCH NEXT FROM SatisfiedUsers INTO @id_utilizador;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Obter a prioridade corrente e o limite do utilizador
        SELECT @prioridade_corrente = u.prioridadecorrente,
               @limite_prioridade = cp.limite_prioridade
        FROM Utilizador u
        JOIN classeprioridade cp ON u.classeprioridadeid = cp.id
        WHERE u.id_utilizador = @id_utilizador;
        -- Bonificar o utilizador, respeitando o limite da classe de prioridade
        IF @prioridade_corrente < @limite_prioridade
        BEGIN
            UPDATE Utilizador
            SET prioridadecorrente = prioridadecorrente + 1
            WHERE id_utilizador = @id_utilizador;
            PRINT 'Bonificação aplicada ao utilizador: ' + @id_utilizador;
        END
        ELSE
        BEGIN
            PRINT 'Utilizador já no limite de prioridade: ' + @id_utilizador;
        END;
        FETCH NEXT FROM SatisfiedUsers INTO @id_utilizador;
    END;
    CLOSE SatisfiedUsers;
    DEALLOCATE SatisfiedUsers;
    PRINT 'Trigger de bonificação concluído.';
END
CREATE TRIGGER GenerateReservationID
ON reserva
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @newID CHAR(8);
    -- Iterar sobre as novas linhas inseridas
    INSERT INTO reserva (id, timestamp, data_inicio, duracao, estado_reserva, id_utilizador)
    SELECT 
        -- Gerar o ID da reserva com MakeID
        dbo.MakeID(GETDATE(), 
            ISNULL(
                (SELECT COUNT(*) + 1 FROM reserva), -- Número sequencial com base no total de reservas
                1 -- Começa com 1 caso não haja reservas
            )
        ),
        i.timestamp,
        i.data_inicio,
        i.duracao,
        i.estado_reserva,
        i.id_utilizador
    FROM inserted i;
    PRINT 'ID da reserva gerado automaticamente.';
END

CREATE TRIGGER GenerateUserID
ON Utilizador
INSTEAD OF INSERT
AS
BEGIN
    -- Inserir registros com ID gerado automaticamente
    INSERT INTO Utilizador (id_utilizador, nome, prefixo, telefone, email, prioridadecorrente, tipoutilizadorid, classeprioridadeid)
    SELECT 
        -- Gerar o ID automaticamente com base no prefixo e no número sequencial
        CASE 
            WHEN i.tipoutilizadorid = 1 THEN 'PR' -- Professor
            WHEN i.tipoutilizadorid = 4 THEN 'MS' -- Estudante de Mestrado
            WHEN i.tipoutilizadorid = 5 THEN 'DS' -- Estudante de Doutoramento
            WHEN i.tipoutilizadorid = 6 THEN 'PD' -- Presidente do Departamento
            ELSE 'OT' -- Outros
        END
        + '_' +
        RIGHT('000000' + CAST(
            ISNULL((
                SELECT MAX(CAST(SUBSTRING(id_utilizador, CHARINDEX('_', id_utilizador) + 1, 6) AS INT))
                FROM Utilizador
                WHERE prefixo = 
                    CASE 
                        WHEN i.tipoutilizadorid = 1 THEN 'PR'
                        WHEN i.tipoutilizadorid = 4 THEN 'MS'
                        WHEN i.tipoutilizadorid = 5 THEN 'DS'
                        WHEN i.tipoutilizadorid = 6 THEN 'PD'
                        ELSE 'OT'
                    END
            ), 0) + 1 -- Incrementa o último ID encontrado ou inicia de 1
            AS VARCHAR), 6) -- Pega os 6 caracteres da direita (formatado)
        AS id_utilizador,
        
        i.nome,
        CASE 
            WHEN i.tipoutilizadorid = 1 THEN 'PR'
            WHEN i.tipoutilizadorid = 4 THEN 'MS'
            WHEN i.tipoutilizadorid = 5 THEN 'DS'
            WHEN i.tipoutilizadorid = 6 THEN 'PD'
            ELSE 'OT'
        END AS prefixo,
        i.telefone,
        i.email,
        i.prioridadecorrente,
        i.tipoutilizadorid,
        i.classeprioridadeid
    FROM inserted i;
END
CREATE TRIGGER PreventUnavailableEquipment
ON reserva_equipamento
INSTEAD OF INSERT
AS
BEGIN
    PRINT 'Trigger para impedir reservas de equipamentos indisponíveis ativado.';
    -- Verificar equipamentos indisponíveis
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN equipamento e ON i.id_equipamento = e.id_equipamento
        WHERE e.estado_equipamento != 0 -- Apenas equipamentos disponíveis podem ser reservados
    )
    BEGIN
        PRINT 'Erro: Tentativa de reservar um equipamento indisponível.';
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    -- Inserir na tabela caso todos os equipamentos estejam disponíveis
    INSERT INTO reserva_equipamento (id_equipamento, id_reserva, imprescindivel)
    SELECT id_equipamento, id_reserva, imprescindivel
    FROM inserted;
    PRINT 'Reserva registrada com sucesso para equipamentos disponíveis.';
END
CREATE TRIGGER PrmoteWaitingReservas
ON equipamento
AFTER UPDATE
AS
BEGIN
    PRINT 'Trigger para promover reservas da lista de espera ativado.';
    -- Promover reservas do estado 'waiting' para 'active' ao liberar equipamentos
    UPDATE reserva
    SET estado_reserva = 'active'
    WHERE id IN (
        SELECT TOP 1 r.id
        FROM reserva r
        JOIN reserva_equipamento re ON r.id = re.id_reserva
        JOIN equipamento e ON re.id_equipamento = e.id_equipamento
        WHERE r.estado_reserva = 'waiting'
          AND e.estado_equipamento = 0 -- Equipamento agora está disponível
          AND NOT EXISTS (
              SELECT 1
              FROM reserva r2
              JOIN reserva_equipamento re2 ON r2.id = re2.id_reserva
              WHERE re2.id_equipamento = e.id_equipamento
                AND r2.estado_reserva = 'active'
          )
        ORDER BY r.data_inicio ASC, r.id_utilizador -- Priorizar pela data de início e ID do utilizador
    );
    PRINT 'Reservas da lista de espera promovidas.';
END
CREATE TRIGGER ReservationPreeption
ON reserva_equipamento
AFTER INSERT
AS
BEGIN
    PRINT 'Trigger de Preempção ativado2.';
    -- Depuração: Verificar dados inseridos
    PRINT 'Linhas inseridas em reserva_equipamento:';
    SELECT * FROM inserted;
    -- Depuração: Verificar possíveis reservas conflitantes
    PRINT 'Reservas conflitantes identificadas:';
    SELECT r1.id AS ReservaConflitante, r2.id AS NovaReserva, re1.id_equipamento
    FROM reserva r1
    JOIN reserva_equipamento re1 ON r1.id = re1.id_reserva
    JOIN inserted i ON re1.id_equipamento = i.id_equipamento
    JOIN reserva r2 ON i.id_reserva = r2.id
    JOIN Utilizador u1 ON r1.id_utilizador = u1.id_utilizador
    JOIN Utilizador u2 ON r2.id_utilizador = u2.id_utilizador
    WHERE r1.estado_reserva = 'active' -- Apenas preempta reservas ativas
      AND r1.data_inicio > DATEADD(HOUR, 48, GETDATE()) -- Apenas reservas com mais de 48h de antecedência
      AND u1.prioridadecorrente < u2.prioridadecorrente -- Prioridade menor
      AND r1.id <> r2.id; -- Reservas diferentes
    -- Atualizar reservas conflitantes para 'waiting'
    UPDATE reserva
    SET estado_reserva = 'waiting'
    WHERE id IN (
        SELECT r1.id
        FROM reserva r1
        JOIN reserva_equipamento re1 ON r1.id = re1.id_reserva
        JOIN inserted i ON re1.id_equipamento = i.id_equipamento
        JOIN reserva r2 ON i.id_reserva = r2.id
        JOIN Utilizador u1 ON r1.id_utilizador = u1.id_utilizador
        JOIN Utilizador u2 ON r2.id_utilizador = u2.id_utilizador
        WHERE r1.estado_reserva = 'active' -- Apenas preempta reservas ativas
          AND r1.data_inicio > DATEADD(HOUR, 48, GETDATE()) -- Apenas reservas com mais de 48h de antecedência
          AND u1.prioridadecorrente < u2.prioridadecorrente -- Prioridade menor
          AND r1.id <> r2.id -- Reservas diferentes
    );
    PRINT 'Preempção aplicada às reservas em conflito2.';
END
CREATE TRIGGER UnifiedReservationTrigger
ON reserva
AFTER UPDATE
AS
BEGIN
    PRINT 'Trigger unificado de reservas ativado.';
    -- Variáveis locais
    DECLARE @id_reserva NVARCHAR(8);
    DECLARE @estado_reserva NVARCHAR(20);
    /* ========================================
       Penalização de reservas esquecidas
    ======================================== */
    PRINT 'Verificando penalizações por reservas esquecidas.';
    UPDATE reserva
    SET estado_reserva = 'forgotten'
    WHERE id IN (
        SELECT r.id
        FROM reserva r
        JOIN inserted i ON r.id = i.id
        WHERE r.estado_reserva IN ('active', 'waiting')
          AND r.data_inicio + r.duracao / 1440 < GETDATE()
          AND i.estado_reserva = r.estado_reserva
    );
    UPDATE Utilizador
    SET prioridadecorrente = CASE 
        WHEN prioridadecorrente > 1 THEN prioridadecorrente - 1
        ELSE 1
    END
    WHERE id_utilizador IN (
        SELECT r.id_utilizador
        FROM reserva r
        WHERE r.estado_reserva = 'forgotten'
    );
    PRINT 'Penalizações aplicadas para reservas esquecidas.';
    /* ========================================
       Criação de requisição ao concluir reserva
    ======================================== */
    PRINT 'Verificando criação de requisição para reservas satisfeitas.';
    SELECT TOP 1 @id_reserva = id
    FROM inserted
    WHERE estado_reserva = 'satisfied';
    IF @id_reserva IS NOT NULL
    BEGIN
        PRINT 'Criando requisição...';
        DECLARE @id_requisicao NVARCHAR(8);
        SET @id_requisicao = dbo.MakeID(GETDATE(), (SELECT COUNT(*) + 1 FROM requisicao WHERE CONVERT(DATE, data_criacao) = CONVERT(DATE, GETDATE())));
        INSERT INTO requisicao (id, estado_requisicao, data_criacao, data_fim, id_reserva)
        VALUES (
            @id_requisicao,
            'active',
            GETDATE(),
            DATEADD(DAY, 7, GETDATE()),
            @id_reserva
        );
        UPDATE equipamento
        SET estado_equipamento = 2
        WHERE id_equipamento IN (
            SELECT id_equipamento
            FROM reserva_equipamento
            WHERE id_reserva = @id_reserva
        );
        INSERT INTO requisicao_equipamento (id_requisicao, id_equipamento)
        SELECT @id_requisicao, id_equipamento
        FROM reserva_equipamento
        WHERE id_reserva = @id_reserva;
        PRINT 'Requisição criada para reserva satisfeita.';
    END;
    /* ========================================
       Cancelamento de reservas
    ======================================== */
    PRINT 'Verificando cancelamento de reservas.';
    -- Impedir cancelamento de reservas no estado satisfied
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE estado_reserva = 'canceled' AND id IN (
            SELECT id
            FROM reserva
            WHERE estado_reserva = 'satisfied'
        )
    )
    BEGIN
        PRINT 'Cancelamento não permitido para reservas no estado satisfied.';
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    -- Liberar equipamentos associados à reserva cancelada
    PRINT 'Liberando equipamentos associados à reserva cancelada.';
    UPDATE equipamento
    SET estado_equipamento = 0
    WHERE id_equipamento IN (
        SELECT id_equipamento
        FROM reserva_equipamento
        WHERE id_reserva IN (
            SELECT id
            FROM inserted
            WHERE estado_reserva = 'canceled'
        )
    );
    -- Promover reservas do estado waiting para active
    PRINT 'Promovendo reservas do estado waiting para active.';
    UPDATE reserva
    SET estado_reserva = 'active'
    WHERE id IN (
        SELECT r1.id
        FROM reserva r1
        JOIN reserva_equipamento re1 ON r1.id = re1.id_reserva
        JOIN reserva_equipamento re2 ON re1.id_equipamento = re2.id_equipamento
        JOIN reserva r2 ON re2.id_reserva = r2.id
        WHERE r1.estado_reserva = 'waiting'
          AND r2.estado_reserva = 'canceled'
    );
    PRINT 'Cancelamento de reserva processado.';
END
CREATE TRIGGER UpdateEquipmentOnRequisitionClosure
ON requisicao
AFTER UPDATE
AS
BEGIN
    PRINT 'Trigger para atualização de equipamentos após fechamento de requisição ativado.';
    -- Atualizar estado dos equipamentos para 'Disponível' (0) ao fechar a requisição
    UPDATE equipamento
    SET estado_equipamento = 0
    WHERE id_equipamento IN (
        SELECT id_equipamento
        FROM requisicao_equipamento
        WHERE id_requisicao IN (
            SELECT id
            FROM inserted
            WHERE estado_requisicao = 'closed'
        )
    );
    PRINT 'Equipamentos atualizados para disponível após fechamento de requisição.';
END
CREATE TRIGGER UpdateEquipmentStateOnInsert
ON reserva_equipamento
AFTER INSERT
AS
BEGIN
    -- Atualizar o estado dos equipamentos associados a reservas 'active'
    UPDATE equipamento
    SET estado_equipamento = 1 -- Estado 'Reservado'
    WHERE id_equipamento IN (
        SELECT i.id_equipamento
        FROM inserted i
        JOIN reserva r ON i.id_reserva = r.id
        WHERE r.estado_reserva = 'active' -- Verifica se a reserva está 'active'
    );
    PRINT 'Estado do equipamento atualizado para Reservado.';
END
CREATE FUNCTION MakeID (@data DATE, @numero INT)
RETURNS CHAR(8)
AS
BEGIN
    -- Variáveis locais para formatar a data e o número
    DECLARE @data_formatada CHAR(6);
    DECLARE @numero_formatado CHAR(2);
    -- Formatar a data como YYMMDD
    SET @data_formatada = CONVERT(CHAR(6), @data, 12);
    -- Formatar o número para ter sempre 2 dígitos
    SET @numero_formatado = RIGHT('00' + CAST(@numero AS VARCHAR), 2);
    -- Concatenar a data e o número para criar o ID
    RETURN @data_formatada + @numero_formatado;
END;
CREATE PROCEDURE CreateReservation
    @timestamp DATETIME,
    @data_inicio DATETIME,
    @duracao INT,
    @id_utilizador VARCHAR(20),
    @id_equipamento INT
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Início da Procedure';
    DECLARE @newID CHAR(8);
    -- Gerar ID da reserva
    BEGIN TRY
        PRINT 'Antes de chamar MakeID';
        SET @newID = dbo.MakeID(
            @data_inicio, 
            (SELECT COUNT(*) + 1 FROM reserva WHERE YEAR(data_inicio) = YEAR(@data_inicio))
        );
        PRINT 'ID gerado: ' + @newID;
    END TRY
    BEGIN CATCH
        PRINT 'Erro ao gerar ID: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
    -- Inserir a nova reserva
    BEGIN TRY
        PRINT 'Antes de inserir na tabela reserva';
        INSERT INTO reserva (id, timestamp, data_inicio, duracao, estado_reserva, id_utilizador)
        VALUES (@newID, @timestamp, @data_inicio, @duracao, 'active', @id_utilizador);
        PRINT 'Reserva inserida com sucesso';
    END TRY
    BEGIN CATCH
        PRINT 'Erro ao inserir na tabela reserva: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
    -- Associar o equipamento
    BEGIN TRY
        PRINT 'Antes de inserir na tabela reserva_equipamento';
        INSERT INTO reserva_equipamento (id_equipamento, id_reserva, imprescindivel)
        VALUES (@id_equipamento, @newID, 1);
        PRINT 'Reserva_equipamento inserido com sucesso';
    END TRY
    BEGIN CATCH
        PRINT 'Erro ao inserir na tabela reserva_equipamento: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
    -- Atualizar o estado do equipamento
    BEGIN TRY
        PRINT 'Antes de atualizar o estado do equipamento';
        UPDATE equipamento
        SET estado_equipamento = 1
        WHERE id_equipamento = @id_equipamento;
        PRINT 'Estado do equipamento atualizado com sucesso';
    END TRY
    BEGIN CATCH
        PRINT 'Erro ao atualizar estado do equipamento: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
    PRINT 'Fim da Procedure';
END;
CREATE PROCEDURE GenerateRequisitionID
    @data DATE,
    @id_requisicao NVARCHAR(8) OUTPUT
AS
BEGIN
    -- Variáveis locais
    DECLARE @data_formatada NVARCHAR(6);
    DECLARE @numero_sequencial NVARCHAR(2);
    -- Formatar a data como YYMMDD
    SET @data_formatada = CONVERT(CHAR(6), @data, 12);
    -- Calcular o próximo número sequencial para o dia
    SET @numero_sequencial = RIGHT('00' + CAST(
        (SELECT COUNT(*) + 1
         FROM requisicao
         WHERE CONVERT(DATE, data_criacao) = @data) AS NVARCHAR), 2);
    -- Concatenar a data formatada com o número sequencial
    SET @id_requisicao = @data_formatada + @numero_sequencial;
END;
CREATE PROCEDURE Reserve2Requisition
    @id_reserva VARCHAR(8)
AS
BEGIN
    -- Verificar se a reserva existe e está no estado correto
    IF EXISTS (
        SELECT 1
        FROM reserva
        WHERE id = @id_reserva AND estado_reserva = 'satisfied'
    )
    BEGIN
        -- Criar a requisição
        INSERT INTO requisicao (id, estado_requisicao, data_criacao, data_fim, id_reserva)
        SELECT 
            'REQ_' + CAST(NEWID() AS VARCHAR(36)), -- Gerar ID único
            'active', -- Estado inicial da requisição
            GETDATE(), -- Data de criação
            DATEADD(DAY, 7, GETDATE()), -- Duração padrão de 7 dias
            @id_reserva -- ID da reserva
        FROM reserva
        WHERE id = @id_reserva;
        -- Atualizar estado do equipamento associado para 'In Use'
        UPDATE equipamento
        SET estado_equipamento = 2
        WHERE id_equipamento IN (
            SELECT id_equipamento
            FROM reserva_equipamento
            WHERE id_reserva = @id_reserva
        );
        PRINT 'Requisição criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT 'A reserva não está no estado correto ou não existe.';
    END
END;