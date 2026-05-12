/**
 * browser_tls NIF — HTTPS client using OpenSSL with configurable TLS fingerprint.
 *
 * Bypasses bot detection (Akamai, Cloudflare, etc.) by producing a JA3 TLS
 * fingerprint matching real browsers (Chrome, Firefox, Safari).
 *
 * The TLS profile (ciphers, curves, sigalgs) is passed from Elixir as strings,
 * so browser profiles can be updated without recompiling C code.
 *
 * Supports:
 *   - HTTPS CONNECT proxy tunneling (like Node.js HttpsProxyAgent)
 *   - gzip / deflate decompression
 *   - Chunked transfer encoding
 *   - Content-Length based reading
 *   - Binary-safe body (PDF, images, etc.)
 *   - Response headers returned to Elixir
 *   - All HTTP methods (GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD)
 *   - Configurable browser TLS profiles from Elixir
 */

#include <erl_nif.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/bio.h>
#include <zlib.h>

#define MAX_RESPONSE (10 * 1024 * 1024)
#define CONNECT_TIMEOUT 30
#define READ_BUF_SIZE 16384

/* Debug: set env BROWSER_TLS_DEBUG=1 to enable verbose logging to stderr */
static int nif_debug_enabled(void) {
    const char *val = getenv("BROWSER_TLS_DEBUG");
    return val && val[0] == '1';
}
#define NIF_DEBUG(fmt, ...) do { if (nif_debug_enabled()) fprintf(stderr, fmt, ##__VA_ARGS__); } while(0)

// ALPN — HTTP/1.1 only (we parse HTTP/1.1 responses)
static const unsigned char BROWSER_ALPN[] = {
    8, 'h', 't', 't', 'p', '/', '1', '.', '1'
};

/* ── Helpers ────────────────────────────────────────────────── */

static int find_header_value(const char *headers, int headers_len,
                             const char *name, char *out, int out_size) {
    int name_len = strlen(name);
    for (int i = 0; i < headers_len - name_len - 2; i++) {
        if ((i == 0 || headers[i-1] == '\n') &&
            strncasecmp(headers + i, name, name_len) == 0 &&
            headers[i + name_len] == ':') {
            int start = i + name_len + 1;
            while (start < headers_len && (headers[start] == ' ' || headers[start] == '\t'))
                start++;
            int end = start;
            while (end < headers_len && headers[end] != '\r' && headers[end] != '\n')
                end++;
            int len = end - start;
            if (len >= out_size) len = out_size - 1;
            memcpy(out, headers + start, len);
            out[len] = 0;
            return len;
        }
    }
    out[0] = 0;
    return 0;
}

static int find_body_offset(const char *response, int response_len) {
    for (int i = 0; i < response_len - 3; i++) {
        if (response[i] == '\r' && response[i+1] == '\n' &&
            response[i+2] == '\r' && response[i+3] == '\n') {
            return i + 4;
        }
    }
    return 0;
}

static int decode_chunked(const char *input, int input_len, char *output, int output_max) {
    int in_pos = 0, out_pos = 0;
    while (in_pos < input_len) {
        int chunk_size = 0;
        while (in_pos < input_len) {
            char c = input[in_pos];
            if (c >= '0' && c <= '9') chunk_size = chunk_size * 16 + (c - '0');
            else if (c >= 'a' && c <= 'f') chunk_size = chunk_size * 16 + (c - 'a' + 10);
            else if (c >= 'A' && c <= 'F') chunk_size = chunk_size * 16 + (c - 'A' + 10);
            else break;
            in_pos++;
        }
        if (in_pos < input_len && input[in_pos] == '\r') in_pos++;
        if (in_pos < input_len && input[in_pos] == '\n') in_pos++;
        if (chunk_size == 0) break;
        if (out_pos + chunk_size > output_max) return -1;
        if (in_pos + chunk_size > input_len) {
            int avail = input_len - in_pos;
            memcpy(output + out_pos, input + in_pos, avail);
            out_pos += avail;
            break;
        }
        memcpy(output + out_pos, input + in_pos, chunk_size);
        out_pos += chunk_size;
        in_pos += chunk_size;
        if (in_pos < input_len && input[in_pos] == '\r') in_pos++;
        if (in_pos < input_len && input[in_pos] == '\n') in_pos++;
    }
    return out_pos;
}

static char *decompress_gzip(const char *input, int input_len, int *out_len) {
    z_stream strm;
    memset(&strm, 0, sizeof(strm));
    if (inflateInit2(&strm, 15 + 32) != Z_OK) return NULL;

    int buf_size = input_len * 4;
    if (buf_size < 65536) buf_size = 65536;
    if (buf_size > MAX_RESPONSE) buf_size = MAX_RESPONSE;

    char *output = malloc(buf_size);
    if (!output) { inflateEnd(&strm); return NULL; }

    strm.next_in = (unsigned char *)input;
    strm.avail_in = input_len;
    strm.next_out = (unsigned char *)output;
    strm.avail_out = buf_size;

    int total = 0, ret;
    do {
        ret = inflate(&strm, Z_NO_FLUSH);
        if (ret == Z_STREAM_ERROR || ret == Z_DATA_ERROR || ret == Z_MEM_ERROR) {
            free(output); inflateEnd(&strm); return NULL;
        }
        total = buf_size - strm.avail_out;
        if (strm.avail_out == 0 && ret != Z_STREAM_END) {
            buf_size *= 2;
            if (buf_size > MAX_RESPONSE) { free(output); inflateEnd(&strm); return NULL; }
            output = realloc(output, buf_size);
            if (!output) { inflateEnd(&strm); return NULL; }
            strm.next_out = (unsigned char *)output + total;
            strm.avail_out = buf_size - total;
        }
    } while (ret != Z_STREAM_END);

    *out_len = total;
    inflateEnd(&strm);
    return output;
}

/* ── TCP / Proxy / SSL ──────────────────────────────────────── */

static int tcp_connect(const char *host, int port) {
    struct addrinfo hints, *res, *p;
    int sockfd;
    char port_str[16];
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    snprintf(port_str, sizeof(port_str), "%d", port);
    if (getaddrinfo(host, port_str, &hints, &res) != 0) return -1;
    for (p = res; p != NULL; p = p->ai_next) {
        sockfd = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
        if (sockfd < 0) continue;
        struct timeval tv = { .tv_sec = CONNECT_TIMEOUT, .tv_usec = 0 };
        setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
        setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
        if (connect(sockfd, p->ai_addr, p->ai_addrlen) == 0) {
            freeaddrinfo(res); return sockfd;
        }
        close(sockfd);
    }
    freeaddrinfo(res);
    return -1;
}

static int proxy_connect(int sockfd, const char *target_host, int target_port,
                         const char *proxy_user, const char *proxy_pass) {
    char buf[4096];
    int len;
    if (proxy_user && proxy_pass && strlen(proxy_user) > 0) {
        char auth_raw[512];
        snprintf(auth_raw, sizeof(auth_raw), "%s:%s", proxy_user, proxy_pass);
        BIO *bio, *b64;
        BUF_MEM *bptr;
        b64 = BIO_new(BIO_f_base64());
        bio = BIO_new(BIO_s_mem());
        bio = BIO_push(b64, bio);
        BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
        BIO_write(bio, auth_raw, strlen(auth_raw));
        BIO_flush(bio);
        BIO_get_mem_ptr(bio, &bptr);
        char auth_b64[1024];
        memcpy(auth_b64, bptr->data, bptr->length);
        auth_b64[bptr->length] = 0;
        BIO_free_all(bio);
        len = snprintf(buf, sizeof(buf),
            "CONNECT %s:%d HTTP/1.1\r\nHost: %s:%d\r\nProxy-Authorization: Basic %s\r\nProxy-Connection: keep-alive\r\n\r\n",
            target_host, target_port, target_host, target_port, auth_b64);
    } else {
        len = snprintf(buf, sizeof(buf),
            "CONNECT %s:%d HTTP/1.1\r\nHost: %s:%d\r\n\r\n",
            target_host, target_port, target_host, target_port);
    }
    if (send(sockfd, buf, len, 0) != len) return -1;
    len = recv(sockfd, buf, sizeof(buf) - 1, 0);
    if (len <= 0) return -1;
    buf[len] = 0;
    if (strstr(buf, "200") == NULL) return -1;
    return 0;
}

/**
 * Create SSL context with configurable browser TLS profile.
 * All parameters are strings passed from Elixir — no hardcoded ciphers.
 */
static SSL_CTX *create_tls_ctx(const char *ciphers, const char *tls13_ciphers,
                                const char *curves_str, const char *sigalgs) {
    SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
    if (!ctx) return NULL;

    SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
    SSL_CTX_set_max_proto_version(ctx, TLS1_3_VERSION);

    if (ciphers && strlen(ciphers) > 0)
        SSL_CTX_set_cipher_list(ctx, ciphers);

    if (tls13_ciphers && strlen(tls13_ciphers) > 0)
        SSL_CTX_set_ciphersuites(ctx, tls13_ciphers);

    if (curves_str && strlen(curves_str) > 0)
        SSL_CTX_set1_groups_list(ctx, curves_str);

    SSL_CTX_set_alpn_protos(ctx, BROWSER_ALPN, sizeof(BROWSER_ALPN));

    if (sigalgs && strlen(sigalgs) > 0)
        SSL_CTX_set1_sigalgs_list(ctx, sigalgs);

    SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, NULL);
    SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_CLIENT);

    return ctx;
}

/* ── Main request function ──────────────────────────────────── */

static int do_https_request(
    const char *method, const char *host, int port, const char *path,
    const char *headers_str, const char *body,
    const char *proxy_host, int proxy_port,
    const char *proxy_user, const char *proxy_pass,
    const char *ciphers, const char *tls13_ciphers,
    const char *curves_str, const char *sigalgs,
    int timeout_ms,
    int *out_status, char **out_body, int *out_body_len,
    char *out_content_type, int ct_size,
    char **out_headers, int *out_headers_len
) {
    int sockfd;
    SSL_CTX *ctx = NULL;
    SSL *ssl = NULL;
    int ret = -1;

    if (proxy_host && strlen(proxy_host) > 0) {
        sockfd = tcp_connect(proxy_host, proxy_port);
        if (sockfd < 0) return -1;
        if (proxy_connect(sockfd, host, port, proxy_user, proxy_pass) < 0) {
            close(sockfd); return -2;
        }
    } else {
        sockfd = tcp_connect(host, port);
        if (sockfd < 0) return -1;
    }

    ctx = create_tls_ctx(ciphers, tls13_ciphers, curves_str, sigalgs);
    if (!ctx) { close(sockfd); return -3; }

    ssl = SSL_new(ctx);
    if (!ssl) { SSL_CTX_free(ctx); close(sockfd); return -4; }

    SSL_set_tlsext_host_name(ssl, host);
    SSL_set_fd(ssl, sockfd);

    if (SSL_connect(ssl) != 1) {
        SSL_free(ssl); SSL_CTX_free(ctx); close(sockfd); return -5;
    }

    char request[65536];
    int req_len;
    char host_header[300];
    if (port != 443)
        snprintf(host_header, sizeof(host_header), "%s:%d", host, port);
    else
        snprintf(host_header, sizeof(host_header), "%s", host);

    if (body && strlen(body) > 0) {
        req_len = snprintf(request, sizeof(request),
            "%s %s HTTP/1.1\r\nHost: %s\r\n%sContent-Length: %zu\r\n\r\n%s",
            method, path, host_header, headers_str, strlen(body), body);
    } else {
        req_len = snprintf(request, sizeof(request),
            "%s %s HTTP/1.1\r\nHost: %s\r\n%s\r\n",
            method, path, host_header, headers_str);
    }

    /* Debug: log request */
    NIF_DEBUG( "[NIF] req_len=%d buf_size=%zu body_len=%zu content_length_header=%zu\n", req_len, sizeof(request), body ? strlen(body) : 0, strlen(body));
    /* Print last 200 chars to see body end */
    if (req_len > 200) {
        NIF_DEBUG( "[NIF] request tail 200: %.200s\n", request + req_len - 200);
    }
    NIF_DEBUG( "[NIF] request first 500: %.500s\n", request);
    if (req_len >= (int)sizeof(request)) {
        NIF_DEBUG( "[NIF] WARNING: request truncated! needed %d, had %zu\n", req_len, sizeof(request));
    }

    if (SSL_write(ssl, request, req_len >= (int)sizeof(request) ? (int)sizeof(request) - 1 : req_len) <= 0) { ret = -6; goto cleanup; }

    /* Set read timeout on socket */
    struct timeval tv;
    tv.tv_sec = timeout_ms / 1000;
    tv.tv_usec = (timeout_ms % 1000) * 1000;
    setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    char *raw = malloc(MAX_RESPONSE);
    if (!raw) { ret = -7; goto cleanup; }

    int total = 0, n;
    int read_retries = 0;
    while (total < MAX_RESPONSE - 1) {
        n = SSL_read(ssl, raw + total, READ_BUF_SIZE);
        if (n > 0) {
            total += n;
            read_retries = 0;
        } else {
            int ssl_err = SSL_get_error(ssl, n);
            if ((ssl_err == SSL_ERROR_WANT_READ || ssl_err == SSL_ERROR_WANT_WRITE) && read_retries < 50) {
                read_retries++;
                usleep(100000); /* 100ms */
                continue;
            }
            NIF_DEBUG( "[NIF] SSL_read returned %d, ssl_err=%d, total=%d, retries=%d\n", n, ssl_err, total, read_retries);
            break;
        }
    }
    raw[total] = 0;

    NIF_DEBUG( "[NIF] Response total=%d bytes, first 200: %.200s\n", total, total > 0 ? raw : "(empty)");

    if (total > 12 && strncmp(raw, "HTTP/", 5) == 0)
        *out_status = atoi(raw + 9);
    else
        *out_status = 0;

    int body_offset = find_body_offset(raw, total);
    int raw_body_len = total - body_offset;
    char *raw_body = raw + body_offset;

    char content_encoding[64] = {0}, transfer_encoding[64] = {0};
    find_header_value(raw, body_offset, "Content-Encoding", content_encoding, sizeof(content_encoding));
    find_header_value(raw, body_offset, "Transfer-Encoding", transfer_encoding, sizeof(transfer_encoding));
    find_header_value(raw, body_offset, "Content-Type", out_content_type, ct_size);

    /* Copia el blob de headers crudos (sin la status line opcionalmente)
       para que Elixir parsee Set-Cookie, Location, etc. */
    if (body_offset > 0) {
        *out_headers = malloc(body_offset + 1);
        if (*out_headers) {
            memcpy(*out_headers, raw, body_offset);
            (*out_headers)[body_offset] = 0;
            *out_headers_len = body_offset;
        } else {
            *out_headers_len = 0;
        }
    } else {
        *out_headers = NULL;
        *out_headers_len = 0;
    }

    char *decoded = NULL;
    int decoded_len = 0;
    if (strcasestr(transfer_encoding, "chunked") != NULL) {
        decoded = malloc(raw_body_len);
        if (!decoded) { free(raw); ret = -8; goto cleanup; }
        decoded_len = decode_chunked(raw_body, raw_body_len, decoded, raw_body_len);
        if (decoded_len < 0) { free(decoded); decoded = NULL; }
    }

    char *body_to_decompress = decoded ? decoded : raw_body;
    int body_to_decompress_len = decoded ? decoded_len : raw_body_len;

    if (strcasestr(content_encoding, "gzip") != NULL ||
        strcasestr(content_encoding, "deflate") != NULL) {
        int decompressed_len = 0;
        char *decompressed = decompress_gzip(body_to_decompress, body_to_decompress_len, &decompressed_len);
        if (decompressed) {
            *out_body = decompressed;
            *out_body_len = decompressed_len;
            if (decoded) free(decoded);
            free(raw);
            ret = 0;
            goto cleanup;
        }
    }

    *out_body = malloc(body_to_decompress_len + 1);
    if (*out_body) {
        memcpy(*out_body, body_to_decompress, body_to_decompress_len);
        (*out_body)[body_to_decompress_len] = 0;
        *out_body_len = body_to_decompress_len;
    } else {
        *out_body_len = 0;
    }

    if (decoded) free(decoded);
    free(raw);
    ret = 0;

cleanup:
    if (ssl) SSL_shutdown(ssl);
    if (ssl) SSL_free(ssl);
    if (ctx) SSL_CTX_free(ctx);
    close(sockfd);
    return ret;
}

/* ── NIF Entry Point ────────────────────────────────────────── */

/**
 * NIF: request/12
 *
 * Args (all charlists):
 *   0: Method    — "GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"
 *   1: URL       — "https://host:port/path"
 *   2: Headers   — "Key: Value\r\nKey2: Value2\r\n"
 *   3: Body      — request body string (or empty)
 *   4: ProxyHost — proxy hostname (or empty for no proxy)
 *   5: ProxyPort — proxy port (integer)
 *   6: ProxyUser — proxy auth username (or empty)
 *   7: ProxyPass — proxy auth password (or empty)
 *   8: Ciphers   — TLS 1.2 cipher string (OpenSSL format)
 *   9: TLS13Ciphers — TLS 1.3 cipher string
 *  10: Curves    — ECDH curves string (e.g. "X25519:P-256:P-384")
 *  11: Sigalgs   — signature algorithms string
 *  12: TimeoutMs — read timeout in milliseconds (integer)
 *
 * Returns: {:ok, status, body_binary, content_type_string} | {:error, reason}
 */
static ERL_NIF_TERM nif_request(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    char method[16], url[2048], headers_str[8192], body[65536];
    char proxy_host[256], proxy_user[256], proxy_pass[256];
    int proxy_port, timeout_ms;
    char ciphers[2048], tls13_ciphers[512], curves[256], sigalgs[512];

    if (argc != 13) return enif_make_badarg(env);

    if (enif_get_string(env, argv[0], method, sizeof(method), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[1], url, sizeof(url), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[2], headers_str, sizeof(headers_str), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[3], body, sizeof(body), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[4], proxy_host, sizeof(proxy_host), ERL_NIF_LATIN1) <= 0 ||
        !enif_get_int(env, argv[5], &proxy_port) ||
        enif_get_string(env, argv[6], proxy_user, sizeof(proxy_user), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[7], proxy_pass, sizeof(proxy_pass), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[8], ciphers, sizeof(ciphers), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[9], tls13_ciphers, sizeof(tls13_ciphers), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[10], curves, sizeof(curves), ERL_NIF_LATIN1) <= 0 ||
        enif_get_string(env, argv[11], sigalgs, sizeof(sigalgs), ERL_NIF_LATIN1) <= 0 ||
        !enif_get_int(env, argv[12], &timeout_ms)) {
        return enif_make_badarg(env);
    }
    if (timeout_ms <= 0) timeout_ms = 30000;

    char host[256] = {0};
    char path[2048] = "/";
    int port = 443;

    if (strncmp(url, "https://", 8) == 0) {
        const char *hp = url + 8;
        const char *slash = strchr(hp, '/');
        const char *colon = strchr(hp, ':');
        if (colon && (!slash || colon < slash)) {
            strncpy(host, hp, colon - hp); host[colon - hp] = 0;
            port = atoi(colon + 1);
            if (slash) { strncpy(path, slash, sizeof(path) - 1); path[sizeof(path)-1] = 0; }
        } else if (slash) {
            strncpy(host, hp, slash - hp); host[slash - hp] = 0;
            strncpy(path, slash, sizeof(path) - 1); path[sizeof(path)-1] = 0;
        } else {
            strncpy(host, hp, sizeof(host) - 1);
        }
    } else {
        return enif_make_tuple2(env, enif_make_atom(env, "error"),
            enif_make_string(env, "only https URLs supported", ERL_NIF_LATIN1));
    }

    int status = 0;
    char *response_body = NULL;
    int response_body_len = 0;
    char content_type[256] = {0};
    char *response_headers = NULL;
    int response_headers_len = 0;

    int result = do_https_request(
        method, host, port, path, headers_str, body,
        strlen(proxy_host) > 0 ? proxy_host : NULL, proxy_port, proxy_user, proxy_pass,
        ciphers, tls13_ciphers, curves, sigalgs, timeout_ms,
        &status, &response_body, &response_body_len, content_type, sizeof(content_type),
        &response_headers, &response_headers_len
    );

    if (result != 0) {
        char err[64];
        snprintf(err, sizeof(err), "request_failed_%d", result);
        if (response_body) free(response_body);
        if (response_headers) free(response_headers);
        return enif_make_tuple2(env, enif_make_atom(env, "error"),
            enif_make_string(env, err, ERL_NIF_LATIN1));
    }

    ERL_NIF_TERM body_term;
    unsigned char *buf = enif_make_new_binary(env, response_body_len, &body_term);
    if (response_body_len > 0 && response_body)
        memcpy(buf, response_body, response_body_len);

    ERL_NIF_TERM headers_term;
    unsigned char *hbuf = enif_make_new_binary(env, response_headers_len, &headers_term);
    if (response_headers_len > 0 && response_headers)
        memcpy(hbuf, response_headers, response_headers_len);

    ERL_NIF_TERM ct_term = enif_make_string(env, content_type, ERL_NIF_LATIN1);
    if (response_body) free(response_body);
    if (response_headers) free(response_headers);

    return enif_make_tuple5(env, enif_make_atom(env, "ok"),
        enif_make_int(env, status), body_term, ct_term, headers_term);
}

static ErlNifFunc nif_funcs[] = {
    {"request", 13, nif_request, ERL_NIF_DIRTY_JOB_IO_BOUND}
};

ERL_NIF_INIT(Elixir.Browser.Tls, nif_funcs, NULL, NULL, NULL, NULL)
