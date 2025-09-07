-- Objeto: Job de Manutenção da Tabela de Logs
-- Descrição: Cria um job que limpa registros antigos da tabela de logs de webhooks.

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name            => 'JOB_LIMPEZA_LOGS_WEBHOOK',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN
                                    DELETE FROM LOG_WEBHOOK_PEDIDOS
                                    WHERE DTA_EVENTO < SYSTIMESTAMP - INTERVAL ''30'' DAY;
                                    COMMIT;
                                END;',
        start_date          => SYSTIMESTAMP,
        repeat_interval     => 'FREQ=MONTHLY;',
        enabled             => TRUE,
        comments            => 'Job para limpar registros da tabela LOG_WEBHOOK_PEDIDOS com mais de 30 dias.'
    );
END;
/