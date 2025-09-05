-- Objeto: Package de Lógica do Webhook
-- Descrição: Encapsula toda a lógica para processar e enviar as notificações.

CREATE OR REPLACE PACKAGE PKG_WEBHOOK_SENDER AS
    PROCEDURE P_NOTIFY_STATUS_CHANGE(
        p_order_id           IN NUMBER,
        p_new_status_code    IN VARCHAR2,
        p_previous_status_code IN VARCHAR2
    );
END PKG_WEBHOOK_SENDER;
/

-- Body da Package
CREATE OR REPLACE PACKAGE BODY PKG_WEBHOOK_SENDER AS

    c_url_webhook CONSTANT VARCHAR2(500) := '[WEBHOOK_URL]';
    c_auth_token  CONSTANT VARCHAR2(1000) := '[SECRET_AUTH_TOKEN]';

    FUNCTION f_translate_status(p_status_code IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE p_status_code
                   WHEN 'A' THEN 'ABERTO'
                   WHEN 'L' THEN 'LIBERADO'
                   WHEN 'F' THEN 'FECHADO'
                   WHEN 'C' THEN 'CANCELADO'
                   ELSE 'INDEFINIDO'
               END;
    END f_translate_status;

    PROCEDURE p_register_log(
        p_order_id   IN NUMBER,
        p_payload    IN CLOB,
        p_status_http IN VARCHAR2 DEFAULT NULL,
        p_error_msg   IN VARCHAR2 DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO WEBHOOK_LOG (ORDER_ID, PAYLOAD_SENT, HTTP_STATUS, ERROR_MESSAGE)
        VALUES (p_order_id, p_payload, p_status_http, p_error_msg);
        COMMIT;
    END p_register_log;

    PROCEDURE P_NOTIFY_STATUS_CHANGE(
        p_order_id           IN NUMBER,
        p_new_status_code    IN VARCHAR2,
        p_previous_status_code IN VARCHAR2
    ) IS
        l_json_payload      CLOB;
        l_new_status_text   VARCHAR2(100);
        l_previous_status_text VARCHAR2(100);
        l_http_req          UTL_HTTP.REQ;
        l_http_resp         UTL_HTTP.RESP;
        l_final_status      VARCHAR2(100);
    BEGIN
        l_new_status_text      := f_translate_status(p_new_status_code);
        l_previous_status_text := f_translate_status(p_previous_status_code);

        l_json_payload := JSON_OBJECT(
            'orderId'        VALUE p_order_id,
            'previousStatus' VALUE l_previous_status_text,
            'newStatus'      VALUE l_new_status_text,
            'timestamp'      VALUE TO_CHAR(SYSTIMESTAMP, 'DD-MM-YYYY HH24:MI:SS')
        );

        l_http_req  := UTL_HTTP.BEGIN_REQUEST(url => c_url_webhook, method => 'POST');
        UTL_HTTP.SET_HEADER(r => l_http_req, name => 'Authorization', value => 'Bearer ' || c_auth_token);
        UTL_HTTP.SET_HEADER(r => l_http_req, name => 'Content-Type', value => 'application/json; charset=utf-8');
        UTL_HTTP.SET_HEADER(r => l_http_req, name => 'Content-Length', value => LENGTH(l_json_payload));
        UTL_HTTP.WRITE_TEXT(r => l_http_req, data => l_json_payload);
        l_http_resp := UTL_HTTP.GET_RESPONSE(r => l_http_req);
        
        l_final_status := l_http_resp.status_code || ' ' || l_http_resp.reason_phrase;
        
        UTL_HTTP.END_RESPONSE(r => l_http_resp);

        p_register_log(
            p_order_id    => p_order_id,
            p_payload     => l_json_payload,
            p_status_http => l_final_status
        );
    EXCEPTION
        WHEN OTHERS THEN
            p_register_log(
                p_order_id  => p_order_id,
                p_payload   => l_json_payload,
                p_error_msg => SQLERRM
            );
    END P_NOTIFY_STATUS_CHANGE;
END PKG_WEBHOOK_SENDER;
/