#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

int32_t last_error_length(void);

int32_t error_message_utf8(char *buf, int32_t length);

int32_t create_wallet(int64_t port, const char *url);

int32_t remove_wallet(int64_t port, const char *url);

int32_t get_mints(int64_t port);

int32_t receive_token(int64_t port, const char *token);

int32_t decode_token(int64_t port, const char *token);

int32_t decode_invoice(int64_t port, const char *invoice);

int32_t pay_invoice(int64_t port, int64_t amount, const char *invoice, const char *mint);

int32_t set_proofs(int64_t port, const char *proofs);

int32_t set_mints(int64_t port, const char *mints);

int32_t get_proofs(int64_t port);

int32_t get_balances(int64_t port);

int32_t send(int64_t port, int64_t amount, const char *active_mint);

int32_t check_spendable(int64_t port, const char *encoded_token);

int32_t request_mint(int64_t port, int64_t amount, const char *mint);

int32_t mint(int64_t port, int64_t amount, const char *hash, const char *mint);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus
