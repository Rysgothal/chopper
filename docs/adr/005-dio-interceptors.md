# ADR 005: Cliente HTTP — Dio com Interceptors Obrigatórios

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Comunicação HTTP robusta é critério iFood ("APIs REST, comunicação assíncrona, problemas de concorrência"). Precisamos:
- Auth token refresh automático (Bearer + refresh token)
- Retry exponencial com jitter (resiliência a 5xx, timeout, network error)
- Logging estruturado (correlacionado com Firebase Performance traces)
- Cache condicional (ETag/If-None-Match para GET idempotentes)
- Configuração por flavor (dev/staging/prod base URLs)

---

## Decisão

### Stack
| Package | Versão | Papel |
|---------|--------|-------|
| `dio` | ^5.4+ | HTTP client moderno, interceptors, transformers |
| `pretty_dio_logger` | ^1.3+ | Logging bonito em dev |
| `dio_cache_interceptor` | ^3.4+ | Cache HTTP (ETag, memória) |

### Interceptors Chain (Ordem Importa)

```dart
// core/network/dio_client.dart
@singleton
class DioClient {
  final Dio _dio;

  DioClient(EnvironmentConfig config, AuthInterceptor authInterceptor, 
            RetryInterceptor retryInterceptor, LoggingInterceptor loggingInterceptor,
            CacheInterceptor cacheInterceptor) {
    _dio = Dio(BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    // ORDEM CRÍTICA: Auth → Retry → Logging → Cache
    _dio.interceptors.addAll([
      authInterceptor,      // 1. Adiciona Authorization; handle 401 → refresh → retry
      retryInterceptor,     // 2. Retry em 5xx/timeout/network (após auth refresh)
      loggingInterceptor,   // 3. Log request/response (inclui trace IDs)
      cacheInterceptor,     // 4. Cache GET idempotentes (ETag)
    ]);
  }

  Dio get instance => _dio;
}
```

### 1. AuthInterceptor (Token Refresh)
```dart
// core/network/interceptors/auth_interceptor.dart
@injectable
class AuthInterceptor extends Interceptor {
  final AuthRepository _authRepository;
  final Lock _refreshLock = Lock(); // Evita race condition múltiplos 401 simultâneos

  AuthInterceptor(this._authRepository);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authRepository.getCurrentAccessToken(); // Em memória ou SecureStorage
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshTokenRequest(err.requestOptions)) {
      await _refreshLock.synchronized(() async {
        // Double-check: outro request já refrescou?
        if (_authRepository.getCurrentAccessToken() != err.requestOptions.headers['Authorization']?.replaceFirst('Bearer ', '')) {
          return handler.next(err); // Já refrescou, segue fluxo normal
        }
        try {
          await _authRepository.refreshToken(); // UseCase chama RefreshTokenUseCase
          // Retry original request com novo token
          final newToken = _authRepository.getCurrentAccessToken()!;
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          await _authRepository.signOut(); // Refresh falhou → logout
          return handler.next(err);
        }
      });
    }
    handler.next(err);
  }

  bool _isRefreshTokenRequest(RequestOptions options) => 
    options.path.contains('/auth/refresh') || options.path.contains('/token');
}
```

### 2. RetryInterceptor (Exponential Backoff + Jitter)
```dart
// core/network/interceptors/retry_interceptor.dart
@injectable
class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final retries = 3;
    final baseDelay = const Duration(seconds: 1);
    
    if (_shouldRetry(err) && err.requestOptions.extra['retryCount'] ?? 0 < retries) {
      final retryCount = (err.requestOptions.extra['retryCount'] ?? 0) + 1;
      final delay = baseDelay * (1 << (retryCount - 1)) + Duration(milliseconds: Random().nextInt(500)); // Jitter
      
      Future.delayed(delay, () {
        err.requestOptions.extra['retryCount'] = retryCount;
        _dio.fetch(err.requestOptions).then(handler.resolve).catchError(handler.next);
      });
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.response?.statusCode ?? 0) >= 500;
  }
}
```

### 3. LoggingInterceptor (Correlacionado com Performance)
```dart
// core/network/interceptors/logging_interceptor.dart
@injectable
class LoggingInterceptor extends Interceptor {
  final FirebasePerformance _performance;

  LoggingInterceptor(this._performance);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Inicia trace de latência da API
    final trace = _performance.newTrace('api_latency')
      ..putAttribute('method', options.method)
      ..putAttribute('path', options.path)
      ..putAttribute('flavor', Environment.name);
    trace.start();
    options.extra['performance_trace'] = trace;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final trace = response.requestOptions.extra['performance_trace'] as Trace?;
    trace?.stop();
    // Log bonito em dev
    if (kDebugMode) prettyDioLogger.log(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final trace = err.requestOptions.extra['performance_trace'] as Trace?;
    trace?.putAttribute('error', err.type.name).stop();
    if (kDebugMode) prettyDioLogger.log(err);
    handler.next(err);
  }
}
```

### 4. CacheInterceptor (Opcional - ETag)
```dart
// core/network/interceptors/cache_interceptor.dart
@injectable
class CacheInterceptor extends Interceptor {
  final CacheStore _memoryCache = CacheStore(); // In-memory, TTL curto (5min)

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET') {
      final cached = _memoryCache.get(options.uri.toString());
      if (cached != null) {
        options.headers['If-None-Match'] = cached.etag;
        // Se 304 Not Modified → handler.resolve(cached.response)
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET' && response.headers.value('ETag') != null) {
      _memoryCache.set(response.requestOptions.uri.toString(), 
        CachedResponse(etag: response.headers.value('ETag')!, response: response));
    }
    handler.next(response);
  }
}
```

---

## Consequências

### Positivas
- ✅ Resiliência enterprise: auth refresh transparente, retry inteligente, observabilidade nativa
- ✅ Traces `api_latency` no Firebase Performance automaticamente
- ✅ Cache condicional reduz banda/latência em GETs repetidos
- ✅ Testável: mock `Dio` + interceptors em unit tests de DataSources

### Negativas/Riscos
- ⚠️ Race condition no refresh token (mitigado: `Lock`/`Completer` singleton)
- ⚠️ Cache in-memory não persiste entre sessões (OK para MVP; Redis/SharedPreferences se escalar)

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **http package** | Leve, padrão Dart | Sem interceptors nativos; retry/manual logging/cache = boilerplate alto | Dio é padrão Flutter enterprise |
| **GraphQL-only (graphql_flutter)** | Cache normalizado, subscriptions | Overkill para CRUD simples; REST + GraphQL híbrido é realista | Vaga pede REST + GraphQL como diferencial |

---

## Referências
- [Dio Docs](https://pub.dev/packages/dio)
- [Dio Interceptors](https://github.com/flutterchina/dio#interceptors)
- [Exponential Backoff](https://aws.amazon.com/pt/blogs/architecture/exponential-backoff-and-jitter/)