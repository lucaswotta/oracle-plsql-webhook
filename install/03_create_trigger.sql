-- Objeto: Trigger de Eventos de Pedido
-- Descrição: Dispara o processo de notificação quando um pedido é alterado na tabela.

CREATE OR REPLACE TRIGGER TRG_SALES_ORDER_STATUS_CHANGE
AFTER UPDATE OF STATUS_COLUMN_NAME ON ERP_SCHEMA.SALES_ORDERS_TABLE
FOR EACH ROW
WHEN (
    NEW.COMPANY_ID_COLUMN = 1 -- Filtro de negócio
    AND NEW.INTEGRATION_USER_COLUMN = 'WEBHOOKER' -- Filtro de usuário
    AND NEW.STATUS_COLUMN_NAME IS NOT NULL 
    AND OLD.STATUS_COLUMN_NAME <> NEW.STATUS_COLUMN_NAME
)
BEGIN
    PKG_WEBHOOK_SENDER.P_NOTIFY_STATUS_CHANGE(
        p_order_id           => :NEW.ORDER_ID_COLUMN,
        p_new_status_code    => :NEW.STATUS_COLUMN_NAME,
        p_previous_status_code => :OLD.STATUS_COLUMN_NAME
    );
END TRG_SALES_ORDER_STATUS_CHANGE;
/