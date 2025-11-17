# Deployment de Contratos de Compliance

Este documento explica cómo desplegar y configurar los contratos de compliance para los tokens RWA.

## 📋 Tabla de Contenidos

- [Contratos Disponibles](#contratos-disponibles)
- [Métodos de Deployment](#métodos-de-deployment)
- [Configuración](#configuración)
- [Ejemplos de Uso](#ejemplos-de-uso)
- [Comparación de Opciones](#comparación-de-opciones)

---

## Contratos Disponibles

### 1. **ComplianceAggregator** (RECOMENDADO)

Un contrato único que implementa todas las reglas de compliance de manera optimizada.

**Características:**
- ✅ Combina 3 reglas de compliance en un solo contrato
- ✅ ~67% ahorro de gas vs módulos separados
- ✅ Gestión centralizada
- ✅ Configuración por token individual

**Reglas incluidas:**
- MaxBalance: Límite de tokens por wallet
- MaxHolders: Límite de número de holders
- TransferLock: Período de bloqueo después de recibir tokens

### 2. **Módulos Individuales**

Contratos separados para cada regla de compliance.

**Contratos:**
- `MaxBalanceCompliance`: Limita balance máximo por wallet
- `MaxHoldersCompliance`: Limita número total de holders
- `TransferLockCompliance`: Impone período de lock después de recibir tokens

**Cuándo usar:**
- Solo necesitas reglas específicas
- Requieres lógica de compliance personalizada
- Necesitas gestión independiente de cada regla

---

## Métodos de Deployment

### Opción 1: Script de Shell (Más Fácil) 🚀

```bash
cd sc

# Simular deployment
./scripts/deploy-compliance.sh

# Deploy real en Anvil local
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/deploy-compliance.sh http://localhost:8545 --broadcast

# Deploy en testnet/mainnet
./scripts/deploy-compliance.sh $RPC_URL --broadcast
```

**Características:**
- ✅ Colorful output
- ✅ Guarda direcciones en JSON
- ✅ Muestra comandos de configuración listos para usar
- ✅ Verifica deployment

### Opción 2: Forge Script (Directo)

```bash
cd sc

# Simular
forge script script/DeployCompliance.s.sol:DeployCompliance

# Deploy en Anvil
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/DeployCompliance.s.sol:DeployCompliance \
  --rpc-url http://localhost:8545 \
  --broadcast

# Deploy en testnet/mainnet con verificación
forge script script/DeployCompliance.s.sol:DeployCompliance \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

---

## Configuración

### Valores por Defecto

Los contratos se despliegan con valores predeterminados razonables:

| Parámetro | Valor por Defecto | Descripción |
|-----------|-------------------|-------------|
| Max Balance | 1,000,000 tokens (10^24 wei) | Balance máximo por wallet |
| Max Holders | 100 | Número máximo de holders |
| Lock Period | 86400 segundos (1 día) | Período de bloqueo post-recepción |

### Configurar ComplianceAggregator

Después del deployment, configura cada token:

```bash
# Configurar token
cast send <AGGREGATOR_ADDRESS> \
  "configureToken(address,uint256,uint256,uint256)" \
  <TOKEN_ADDRESS> \
  1000000000000000000000000 \    # 1M tokens
  100 \                           # 100 max holders
  86400 \                         # 1 day lock
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# Agregar aggregator al token
cast send <TOKEN_ADDRESS> \
  "addComplianceModule(address)" \
  <AGGREGATOR_ADDRESS> \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

### Configurar Módulos Individuales

Para cada módulo que quieras usar:

#### MaxBalanceCompliance

```bash
# 1. Vincular token
cast send <MODULE_ADDRESS> \
  "bindToken(address)" \
  <TOKEN_ADDRESS> \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 2. Configurar max balance
cast send <MODULE_ADDRESS> \
  "setMaxBalance(address,uint256)" \
  <TOKEN_ADDRESS> \
  1000000000000000000000000 \  # 1M tokens
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 3. Agregar al token
cast send <TOKEN_ADDRESS> \
  "addComplianceModule(address)" \
  <MODULE_ADDRESS> \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

#### MaxHoldersCompliance

```bash
# 1. Vincular token
cast send <MODULE_ADDRESS> \
  "bindToken(address)" \
  <TOKEN_ADDRESS> \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 2. Configurar max holders
cast send <MODULE_ADDRESS> \
  "setMaxHolders(address,uint256)" \
  <TOKEN_ADDRESS> \
  100 \  # 100 holders
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 3. Agregar al token
cast send <TOKEN_ADDRESS> \
  "addComplianceModule(address)" \
  <MODULE_ADDRESS> \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

#### TransferLockCompliance

```bash
# 1. Vincular token
cast send <MODULE_ADDRESS> \
  "bindToken(address)" \
  <TOKEN_ADDRESS> \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 2. Configurar lock period
cast send <MODULE_ADDRESS> \
  "setLockPeriod(address,uint256)" \
  <TOKEN_ADDRESS> \
  86400 \  # 1 day in seconds
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 3. Agregar al token
cast send <TOKEN_ADDRESS> \
  "addComplianceModule(address)" \
  <MODULE_ADDRESS> \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

---

## Ejemplos de Uso

### Ejemplo Completo: ComplianceAggregator

```bash
# 1. Desplegar contratos
cd sc
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
./scripts/deploy-compliance.sh http://localhost:8545 --broadcast

# Las direcciones se guardan en:
cat deployments/compliance-addresses.json

# 2. Asumir direcciones del output:
AGGREGATOR=0x5b73c5498c1e3b4dba84de0f1833c4a029d90519
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# 3. Configurar token
cast send $AGGREGATOR \
  "configureToken(address,uint256,uint256,uint256)" \
  $TOKEN \
  5000000000000000000000000 \    # 5M tokens max
  50 \                             # 50 holders max
  172800 \                         # 2 days lock
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 4. Agregar compliance al token
cast send $TOKEN \
  "addComplianceModule(address)" \
  $AGGREGATOR \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

# 5. Verificar configuración
cast call $AGGREGATOR \
  "getTokenConfig(address)" \
  $TOKEN \
  --rpc-url http://localhost:8545

# 6. Probar transfer (debe respetar compliance)
cast send $TOKEN \
  "transfer(address,uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  1000000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

### Ejemplo: Módulos Individuales

```bash
# 1. Desplegar
./scripts/deploy-compliance.sh http://localhost:8545 --broadcast

# Direcciones de ejemplo
MAX_BALANCE=0x7fa9385be102ac3eac297483dd6233d62b3e1496
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# 2. Configurar solo MaxBalance
cast send $MAX_BALANCE \
  "bindToken(address)" \
  $TOKEN \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

cast send $MAX_BALANCE \
  "setMaxBalance(address,uint256)" \
  $TOKEN \
  10000000000000000000000000 \  # 10M tokens
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY

cast send $TOKEN \
  "addComplianceModule(address)" \
  $MAX_BALANCE \
  --rpc-url http://localhost:8545 \
  --private-key $PRIVATE_KEY
```

---

## Comparación de Opciones

### Costos de Gas

| Operación | ComplianceAggregator | 3 Módulos Separados | Ahorro |
|-----------|---------------------|---------------------|--------|
| Transfer | ~120k gas | ~360k gas | ~67% |
| Deploy | ~2.5M gas | ~3.5M gas | ~29% |
| Configuración | 1 tx | 9 txs (3 per módulo) | ~89% |

### Características Comparadas

| Característica | ComplianceAggregator | Módulos Individuales |
|----------------|---------------------|---------------------|
| **Gas por transfer** | ⭐⭐⭐⭐⭐ Muy Bajo | ⭐⭐ Alto |
| **Flexibilidad** | ⭐⭐⭐ Media | ⭐⭐⭐⭐⭐ Alta |
| **Facilidad de uso** | ⭐⭐⭐⭐⭐ Muy Fácil | ⭐⭐⭐ Media |
| **Gestión centralizada** | ✅ Sí | ❌ No |
| **Configuración por token** | ✅ Independiente | ✅ Independiente |
| **Reglas personalizadas** | ❌ Fijas | ✅ Flexibles |

### Recomendaciones

**Usa ComplianceAggregator si:**
- ✅ Necesitas las 3 reglas estándar
- ✅ Quieres optimizar costos de gas
- ✅ Prefieres gestión simple y centralizada
- ✅ Tienes múltiples tokens con compliance similar

**Usa Módulos Individuales si:**
- ✅ Solo necesitas 1-2 reglas específicas
- ✅ Requieres lógica de compliance personalizada
- ✅ Necesitas actualizar reglas independientemente
- ✅ Tienes requirements muy específicos por regulación

---

## 🔍 Verificar Deployment

### Verificar Contratos Deployed

```bash
# Verificar ComplianceAggregator
cast call <AGGREGATOR_ADDRESS> "owner()" --rpc-url http://localhost:8545

# Verificar módulo individual
cast call <MODULE_ADDRESS> "owner()" --rpc-url http://localhost:8545
cast call <MODULE_ADDRESS> "maxBalance()" --rpc-url http://localhost:8545
```

### Verificar Configuración de Token

```bash
# Ver config en Aggregator
cast call <AGGREGATOR_ADDRESS> \
  "getTokenConfig(address)" \
  <TOKEN_ADDRESS> \
  --rpc-url http://localhost:8545

# Ver módulos en token
cast call <TOKEN_ADDRESS> \
  "getComplianceModules()" \
  --rpc-url http://localhost:8545
```

---

## 📝 Archivo de Direcciones

Después del deployment, las direcciones se guardan en:

```
sc/deployments/compliance-addresses.json
```

Formato:

```json
{
  "network": "http://localhost:8545",
  "timestamp": "2025-11-11T12:00:00Z",
  "contracts": {
    "ComplianceAggregator": "0x...",
    "MaxBalanceCompliance": "0x...",
    "MaxHoldersCompliance": "0x...",
    "TransferLockCompliance": "0x..."
  }
}
```

---

## 🚨 Troubleshooting

### Error: "Only owner can call this function"

Asegúrate de que estás usando la private key del deployer/owner:

```bash
export PRIVATE_KEY=<OWNER_PRIVATE_KEY>
```

### Error: "Token already configured"

Si necesitas reconfigurar, primero desvincula el token o despliega nuevo aggregator.

### Error: "Compliance check failed"

Verifica que:
1. El módulo está agregado al token
2. La configuración es correcta
3. El transfer cumple con las reglas

---

## 📚 Recursos Adicionales

- [Documentación de ComplianceAggregator](./sc/src/compliance/ComplianceAggregator.sol)
- [Tests de Compliance](./sc/test/)
- [Script de Deployment Completo](./sc/scripts/deploy-complete-auto.sh)

---

## ✅ Checklist de Deployment

- [ ] Contratos compilados sin errores
- [ ] Deployment simulado exitoso
- [ ] Deployment en blockchain realizado
- [ ] Direcciones guardadas en JSON
- [ ] Token configurado con compliance
- [ ] Módulos agregados al token
- [ ] Transfers de prueba funcionando
- [ ] Compliance rules verificadas

---

**Última actualización:** 2025-11-11

