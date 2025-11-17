# 📚 Guía del Estudiante: Compliance Modules

## 🎯 Objetivo de Aprendizaje

Entender cómo funcionan los **módulos de compliance** en tokens de seguridad (Security Tokens) y cómo implementarlos en la práctica.

---

## 📖 Conceptos Fundamentales

### ¿Qué es Compliance?

**Compliance** = Cumplimiento de reglas regulatorias

En el mundo de las criptomonedas y tokens de seguridad, compliance significa:
- ✅ Verificar que los holders cumplen con requisitos legales
- ✅ Limitar transferencias según reglas específicas
- ✅ Proteger a la empresa emisora de problemas legales

### ¿Por qué necesitamos Compliance Modules?

Imagina que emites un token que representa acciones de tu empresa:

**Sin compliance:**
```
❌ Cualquiera puede comprar tus tokens
❌ Alguien podría comprar el 100% del supply
❌ Podrías violar regulaciones de valores
❌ Problemas legales graves
```

**Con compliance:**
```
✅ Solo inversores verificados pueden comprar
✅ Límites de tokens por persona
✅ Límites de número de inversores
✅ Cumplimiento legal automático
```

---

## 🧩 Los 3 Módulos de Compliance

### 1. MaxBalanceCompliance

**¿Qué hace?**  
Limita cuántos tokens puede tener una wallet.

**Ejemplo práctico:**
```
Emisión total: 1,000,000 tokens
Límite por wallet: 50,000 tokens (5%)

✅ Usuario A compra 30,000 tokens → OK
✅ Usuario A compra 15,000 más → OK (total: 45,000)
❌ Usuario A intenta comprar 10,000 más → FALLA (excedería 50,000)
```

**¿Por qué es útil?**
- Previene concentración de poder
- Cumple regulaciones que limitan participación individual
- Protege contra manipulación del mercado

**Código del contrato:**
```solidity
function canTransfer(
    address _from,
    address _to,
    uint256 _value
) external view returns (bool) {
    uint256 newBalance = balanceOf(_to) + _value;
    return newBalance <= maxBalance;
}
```

### 2. MaxHoldersCompliance

**¿Qué hace?**  
Limita el número total de personas que pueden tener el token.

**Ejemplo práctico:**
```
Límite de holders: 100 personas
Holders actuales: 99

✅ Nueva persona compra tokens → OK (holder #100)
❌ Otra persona intenta comprar → FALLA (ya hay 100 holders)
✅ Holder existente compra más → OK (no aumenta el conteo)
```

**¿Por qué es útil?**
- Requerido en algunas jurisdicciones (ej: max 99 inversores en securities privados)
- Simplifica reporting regulatorio
- Reduce complejidad administrativa

**Código del contrato:**
```solidity
function canTransfer(
    address _from,
    address _to,
    uint256 _value
) external view returns (bool) {
    // Si el destinatario ya tiene tokens, no cuenta como nuevo holder
    if (balanceOf(_to) > 0) {
        return true;
    }
    
    // Si es nuevo holder, verificar límite
    return holderCount < maxHolders;
}
```

### 3. TransferLockCompliance

**¿Qué hace?**  
Bloquea tokens por un tiempo después de recibirlos.

**Ejemplo práctico:**
```
Período de lock: 24 horas

Día 1, 10:00 AM → Usuario compra tokens
Día 1, 02:00 PM → Usuario intenta vender → ❌ FALLA (aún bloqueados)
Día 2, 10:01 AM → Usuario intenta vender → ✅ OK (24h pasaron)
```

**¿Por qué es útil?**
- Previene "pump and dump"
- Cumple períodos de lock-up requeridos
- Reduce volatilidad del mercado
- Fomenta inversión a largo plazo

**Código del contrato:**
```solidity
function canTransfer(
    address _from,
    address _to,
    uint256 _value
) external view returns (bool) {
    uint256 lastReceived = lastReceiveTime[_from];
    uint256 timePassed = block.timestamp - lastReceived;
    
    return timePassed >= lockPeriod;
}
```

---

## 🔧 Arquitectura del Sistema

### Flujo de Verificación

```
Usuario intenta transferir tokens
         ↓
Token contract recibe la solicitud
         ↓
¿Hay módulos de compliance?
         ↓
    [SÍ] → Llama a cada módulo
         ↓
    Módulo 1: MaxBalance → ¿Cumple? ✅
    Módulo 2: MaxHolders → ¿Cumple? ✅  
    Módulo 3: TransferLock → ¿Cumple? ✅
         ↓
    ¿Todos pasaron? → SÍ
         ↓
    Transfer ejecutado ✅
```

### Diagrama de Componentes

```
┌─────────────────────────────────────┐
│         Security Token              │
│  (Token.sol / TokenCloneable.sol)   │
└───────────┬─────────────────────────┘
            │
            │ complianceModules[]
            │
     ┌──────┴──────┬──────────┬────────────┐
     │             │          │            │
     ▼             ▼          ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────┐
│MaxBalance│ │MaxHolders│ │TransferL│  │ ... │
│Compliance│ │Compliance│ │ock Comp │  │Más? │
└──────────┘ └──────────┘ └──────────┘  └─────┘
```

---

## 💻 Ejercicios Prácticos

### Ejercicio 1: Deploy y Configuración Básica

**Objetivo:** Desplegar un módulo de compliance y conectarlo a un token.

```bash
# 1. Compilar contratos
cd sc
forge build

# 2. Desplegar módulos de compliance
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/deploy-compliance.sh http://localhost:8545 --broadcast

# 3. Anotar las direcciones desplegadas
# MaxBalanceCompliance: 0x...
# Supongamos: 0x7fa9385be102ac3eac297483dd6233d62b3e1496

# 4. Crear variables
MAX_BALANCE=0x7fa9385be102ac3eac297483dd6233d62b3e1496
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# 5. Vincular el módulo al token
cast send $MAX_BALANCE \
  "bindToken(address)" \
  $TOKEN \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 6. Configurar límite (ejemplo: 100,000 tokens)
cast send $MAX_BALANCE \
  "setMaxBalance(address,uint256)" \
  $TOKEN \
  100000000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 7. Agregar el módulo al token
cast send $TOKEN \
  "addComplianceModule(address)" \
  $MAX_BALANCE \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

**Verificación:**
```bash
# Ver módulos activos en el token
cast call $TOKEN \
  "getComplianceModules()" \
  --rpc-url http://localhost:8545
```

### Ejercicio 2: Probar Límites de Balance

**Objetivo:** Verificar que el módulo MaxBalance funciona correctamente.

```bash
# Variables
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd
ACCOUNT1=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
ACCOUNT2=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
PRIVATE_KEY1=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
PRIVATE_KEY2=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# 1. Verificar balance inicial de Account2
cast call $TOKEN "balanceOf(address)" $ACCOUNT2 --rpc-url http://localhost:8545

# 2. Enviar tokens dentro del límite (50,000 tokens)
cast send $TOKEN \
  "transfer(address,uint256)" \
  $ACCOUNT2 \
  50000000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY1

# ✅ Debería funcionar

# 3. Intentar enviar más y exceder el límite (60,000 tokens más)
cast send $TOKEN \
  "transfer(address,uint256)" \
  $ACCOUNT2 \
  60000000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY1

# ❌ Debería fallar con error de compliance
```

### Ejercicio 3: Configurar Múltiples Módulos

**Objetivo:** Aprender a combinar varios módulos de compliance.

```bash
# Variables de módulos
MAX_BALANCE=0x7fa9385be102ac3eac297483dd6233d62b3e1496
MAX_HOLDERS=0x34a1d3fff3958843c43ad80f30b94c510645c316
TRANSFER_LOCK=0x90193c961a926261b756d1e5bb255e67ff9498a1
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# 1. Configurar MaxBalance (ya hecho en ejercicio 1)

# 2. Configurar MaxHolders
cast send $MAX_HOLDERS "bindToken(address)" $TOKEN \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

cast send $MAX_HOLDERS "setMaxHolders(address,uint256)" $TOKEN 50 \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

cast send $TOKEN "addComplianceModule(address)" $MAX_HOLDERS \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

# 3. Configurar TransferLock
cast send $TRANSFER_LOCK "bindToken(address)" $TOKEN \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

cast send $TRANSFER_LOCK "setLockPeriod(address,uint256)" $TOKEN 3600 \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

cast send $TOKEN "addComplianceModule(address)" $TRANSFER_LOCK \
  --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY

# 4. Verificar todos los módulos
cast call $TOKEN "getComplianceModules()" --rpc-url http://localhost:8545
```

---

## 🧪 Casos de Prueba

### Caso 1: Transfer Normal (Todo Cumple)

```bash
# Setup: MaxBalance = 100K, destinatario tiene 50K
cast send $TOKEN "transfer(address,uint256)" $ACCOUNT2 30000000000000000000000

# Expectativa: ✅ Éxito (50K + 30K = 80K < 100K)
```

### Caso 2: Exceder MaxBalance

```bash
# Setup: MaxBalance = 100K, destinatario tiene 90K
cast send $TOKEN "transfer(address,uint256)" $ACCOUNT2 20000000000000000000000

# Expectativa: ❌ Fallo (90K + 20K = 110K > 100K)
# Error: "Transfer would exceed max balance"
```

### Caso 3: Exceder MaxHolders

```bash
# Setup: MaxHolders = 50, ya hay 50 holders, destinatario es nuevo
cast send $TOKEN "transfer(address,uint256)" $NEW_ACCOUNT 1000000000000000000000

# Expectativa: ❌ Fallo (50 holders actuales + 1 nuevo > 50 max)
# Error: "Would exceed max holders"
```

### Caso 4: Transfer Durante Lock Period

```bash
# Setup: Lock = 1 hora, tokens recibidos hace 30 min
cast send $TOKEN "transfer(address,uint256)" $ACCOUNT3 1000000000000000000000

# Expectativa: ❌ Fallo (30 min < 1 hora)
# Error: "Tokens are locked"

# Esperar 30 min más e intentar de nuevo
# Expectativa: ✅ Éxito (60 min >= 1 hora)
```

---

## 📊 Tabla de Decisiones

| Escenario | MaxBalance | MaxHolders | TransferLock | Resultado |
|-----------|------------|------------|--------------|-----------|
| Transfer a holder existente, balance OK, sin lock | ✅ | ✅ | ✅ | ✅ ÉXITO |
| Transfer excede max balance | ❌ | ✅ | ✅ | ❌ FALLO |
| Transfer a nuevo holder, ya hay max | ✅ | ❌ | ✅ | ❌ FALLO |
| Transfer durante período de lock | ✅ | ✅ | ❌ | ❌ FALLO |
| Transfer excede balance Y nuevo holder | ❌ | ❌ | ✅ | ❌ FALLO |

---

## 🎓 Evaluación de Conocimientos

### Preguntas Teóricas

1. **¿Qué pasaría si no usáramos módulos de compliance en un security token?**
   <details>
   <summary>Ver respuesta</summary>
   Podría haber problemas legales graves, como violar regulaciones de valores, permitir concentración de propiedad no permitida, o facilitar lavado de dinero.
   </details>

2. **¿Por qué MaxHolders no cuenta a holders existentes al transferir?**
   <details>
   <summary>Ver respuesta</summary>
   Porque no aumenta el número total de holders. Si alguien que ya tiene tokens compra más, sigue siendo solo 1 holder.
   </details>

3. **¿Cuál es la diferencia entre `bindToken()` y `addComplianceModule()`?**
   <details>
   <summary>Ver respuesta</summary>
   - `bindToken()`: Se llama en el módulo de compliance, vincula el módulo a un token específico
   - `addComplianceModule()`: Se llama en el token, agrega un módulo a la lista de verificaciones
   Ambos son necesarios para la integración completa.
   </details>

### Ejercicios Avanzados

**Ejercicio A:** Crear un script que configure automáticamente todos los módulos para un nuevo token.

**Ejercicio B:** Implementar un módulo de compliance personalizado que permita transferencias solo en días hábiles.

**Ejercicio C:** Crear un dashboard que muestre el estado de compliance de un token en tiempo real.

---

## 🔗 Recursos Adicionales

### Documentación Técnica
- [ICompliance.sol](./sc/src/ICompliance.sol) - Interface de compliance
- [MaxBalanceCompliance.sol](./sc/src/compliance/MaxBalanceCompliance.sol)
- [MaxHoldersCompliance.sol](./sc/src/compliance/MaxHoldersCompliance.sol)
- [TransferLockCompliance.sol](./sc/src/compliance/TransferLockCompliance.sol)

### Scripts Útiles
- [deploy-compliance.sh](./sc/scripts/deploy-compliance.sh) - Deploy automatizado
- [GUIA_COMANDOS.md](./GUIA_COMANDOS.md) - Referencia rápida de comandos

### Testing
- [MaxBalanceCompliance.t.sol](./sc/test/MaxBalanceCompliance.t.sol)
- [MaxHoldersCompliance.t.sol](./sc/test/MaxHoldersCompliance.t.sol)
- [TransferLockCompliance.t.sol](./sc/test/TransferLockCompliance.t.sol)

---

## ✅ Checklist de Progreso

- [ ] Entiendo qué es compliance y por qué es necesario
- [ ] Puedo explicar cada uno de los 3 módulos de compliance
- [ ] He desplegado módulos de compliance en Anvil local
- [ ] He configurado exitosamente un módulo en un token
- [ ] He probado transfers que pasan compliance
- [ ] He probado transfers que fallan compliance
- [ ] Puedo configurar múltiples módulos en un token
- [ ] Entiendo cómo verificar el estado de compliance
- [ ] Puedo troubleshoot problemas comunes
- [ ] Estoy listo para trabajar con compliance en producción

---

## 🆘 Ayuda y Soporte

**Problemas comunes:**

1. **"Transfer reverted" sin mensaje específico**
   - Verificar que el módulo está correctamente vinculado
   - Verificar que el módulo está en la lista del token
   - Revisar los logs del transaction

2. **"Only owner can call this function"**
   - Asegurarse de usar la private key correcta
   - Verificar que eres el owner del contrato

3. **Los módulos no se aplican**
   - Verificar que se llamó `bindToken()`
   - Verificar que se llamó `addComplianceModule()`
   - Ver la lista de módulos con `getComplianceModules()`

---

**¡Felicidades! Has completado la guía de Compliance Modules.** 🎉

Ahora estás listo para implementar compliance en security tokens de manera profesional.

