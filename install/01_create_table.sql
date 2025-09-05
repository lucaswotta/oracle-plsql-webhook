-- Objeto: Tabela de Log para Webhooks
-- Descrição: Armazena o histórico das tentativas de notificação.

CREATE TABLE WEBHOOK_LOG (
    LOG_ID          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    EVENT_TIMESTAMP TIMESTAMP DEFAULT SYSTIMESTAMP,
    ORDER_ID        NUMBER,
    PAYLOAD_SENT    CLOB,
    HTTP_STATUS     VARCHAR2(100),
    ERROR_MESSAGE   VARCHAR2(4000)
);

COMMENT ON TABLE WEBHOOK_LOG IS
'Log de auditoria para notificações enviadas via webhook.';