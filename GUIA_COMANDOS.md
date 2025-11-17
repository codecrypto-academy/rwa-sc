# 🔧 Guía de Comandos - RWA Security Tokens

Referencia rápida de comandos para trabajar con el sistema RWA.

---

## 📋 Tabla de Contenidos

- [Setup Inicial](#setup-inicial)
- [Compilación y Testing](#compilación-y-testing)
- [Deployment](#deployment)
- [Compliance Modules](#compliance-modules)
- [Token Operations](#token-operations)
- [Identity Management](#identity-management)
- [Trusted Issuers](#trusted-issuers)
- [Verificación y Debugging](#verificación-y-debugging)
- [Variables de Entorno](#variables-de-entorno)

---

## Setup Inicial

### Configurar Entorno

```bash
# Clonar repositorio (si aplica)
cd "/Users/joseviejo/2025/cc/PROYECTOS TRAINING/56_RWA_SC"

# Ir al directorio de contratos
cd sc

# Instalar dependencias de Foundry
forge install

# Compilar contratos
forge build
```

### Iniciar Anvil Local

```bash
# En una terminal separada
anvil

# O con el script automatizado
./scripts/deploy-complete-auto.sh
```

### Configurar Private Key

```bash
# Private key del primer account de Anvil
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Private key del segundo account
export PRIVATE_KEY2=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# RPC URL
export RPC_URL=http://localhost:8545
```

---

## Compilación y Testing

### Compilar Contratos

```bash
# Compilar todos los contratos
forge build

# Compilar sin tests
forge build --skip test

# Limpiar y recompilar
forge clean && forge build

# Ver warnings
forge build --force
```

### Ejecutar Tests

```bash
# Todos los tests
forge test

# Tests específicos
forge test --match-contract MaxBalanceCompliance
forge test --match-test testTransfer

# Con verbosidad
forge test -vvv

# Con gas report
forge test --gas-report

# Tests de un archivo específico
forge test --match-path test/MaxBalanceCompliance.t.sol
```

### Coverage

```bash
# Ver coverage de tests
forge coverage

# Coverage detallado
forge coverage --report lcov
```

---

## Deployment

### Deploy Completo del Sistema

```bash
# Deploy automatizado (Anvil)
./scripts/deploy-complete-auto.sh

# Deploy manual paso a paso
forge script script/DeployIdentityCloneFactory.s.sol --rpc-url $RPC_URL --broadcast
forge script script/DeployIdentityRegistry.s.sol --rpc-url $RPC_URL --broadcast
forge script script/DeployTrustedIssuersRegistry.s.sol --rpc-url $RPC_URL --broadcast
forge script script/DeployTokenCloneFactory.s.sol --rpc-url $RPC_URL --broadcast
```

### Deploy Compliance Modules

```bash
# Simulación (sin deploy)
./scripts/deploy-compliance.sh

# Deploy real en Anvil
./scripts/deploy-compliance.sh http://localhost:8545 --broadcast

# Deploy con verificación (testnet/mainnet)
forge script script/DeployCompliance.s.sol \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

### Crear Token

```bash
# Usando la factory
cast send <TOKEN_FACTORY_ADDRESS> \
  "createToken(string,string,uint8,uint256,address,address)" \
  "My Token" \
  "MTK" \
  18 \
  1000000000000000000000000 \
  <IDENTITY_REGISTRY> \
  <TRUSTED_ISSUERS_REGISTRY> \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## Compliance Modules

### Configurar MaxBalanceCompliance

```bash
# Variables
MAX_BALANCE=0x7fa9385be102ac3eac297483dd6233d62b3e1496
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# 1. Bind token al módulo
cast send $MAX_BALANCE \
  "bindToken(address)" \
  $TOKEN \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# 2. Configurar límite (1M tokens = 10^24 wei)
cast send $MAX_BALANCE \
  "setMaxBalance(address,uint256)" \
  $TOKEN \
  1000000000000000000000000 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# 3. Agregar módulo al token
cast send $TOKEN \
  "addComplianceModule(address)" \
  $MAX_BALANCE \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Ver configuración
cast call $MAX_BALANCE "maxBalance()" --rpc-url $RPC_URL
```

### Configurar MaxHoldersCompliance

```bash
MAX_HOLDERS=0x34a1d3fff3958843c43ad80f30b94c510645c316
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# Bind y configurar
cast send $MAX_HOLDERS "bindToken(address)" $TOKEN \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send $MAX_HOLDERS "setMaxHolders(address,uint256)" $TOKEN 100 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send $TOKEN "addComplianceModule(address)" $MAX_HOLDERS \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Ver holders actuales
cast call $MAX_HOLDERS "holderCount()" --rpc-url $RPC_URL
cast call $MAX_HOLDERS "maxHolders()" --rpc-url $RPC_URL
```

### Configurar TransferLockCompliance

```bash
TRANSFER_LOCK=0x90193c961a926261b756d1e5bb255e67ff9498a1
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# Bind y configurar (86400 = 1 día en segundos)
cast send $TRANSFER_LOCK "bindToken(address)" $TOKEN \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send $TRANSFER_LOCK "setLockPeriod(address,uint256)" $TOKEN 86400 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send $TOKEN "addComplianceModule(address)" $TRANSFER_LOCK \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Ver lock period
cast call $TRANSFER_LOCK "lockPeriod()" --rpc-url $RPC_URL
```

### Remover Módulo de Compliance

```bash
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# Ver índices de módulos
cast call $TOKEN "getComplianceModules()" --rpc-url $RPC_URL

# Remover módulo por índice (ej: índice 0)
cast send $TOKEN \
  "removeComplianceModule(uint256)" \
  0 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## Token Operations

### Transfers

```bash
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd
RECIPIENT=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# Transfer simple (1000 tokens = 10^21 wei)
cast send $TOKEN \
  "transfer(address,uint256)" \
  $RECIPIENT \
  1000000000000000000000 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Transfer con gas limit específico
cast send $TOKEN \
  "transfer(address,uint256)" \
  $RECIPIENT \
  1000000000000000000000 \
  --gas-limit 500000 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

### Mint Tokens

```bash
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd
RECIPIENT=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# Mint tokens (requiere MINT_ROLE)
cast send $TOKEN \
  "mint(address,uint256)" \
  $RECIPIENT \
  5000000000000000000000 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

### Burn Tokens

```bash
# Burn tokens propios
cast send $TOKEN \
  "burn(uint256)" \
  1000000000000000000000 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Burn tokens de otro (requiere allowance)
cast send $TOKEN \
  "burnFrom(address,uint256)" \
  $OTHER_ADDRESS \
  1000000000000000000000 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

### Pausar/Despausar Token

```bash
# Pausar (requiere DEFAULT_ADMIN_ROLE)
cast send $TOKEN "pause()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Despausar
cast send $TOKEN "unpause()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Ver estado
cast call $TOKEN "paused()" --rpc-url $RPC_URL
```

### Información del Token

```bash
TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd

# Información básica
cast call $TOKEN "name()" --rpc-url $RPC_URL
cast call $TOKEN "symbol()" --rpc-url $RPC_URL
cast call $TOKEN "decimals()" --rpc-url $RPC_URL
cast call $TOKEN "totalSupply()" --rpc-url $RPC_URL

# Balance de una cuenta
cast call $TOKEN "balanceOf(address)" $ACCOUNT --rpc-url $RPC_URL

# Allowance
cast call $TOKEN "allowance(address,address)" $OWNER $SPENDER --rpc-url $RPC_URL

# Módulos de compliance
cast call $TOKEN "getComplianceModules()" --rpc-url $RPC_URL

# Registries asociados
cast call $TOKEN "identityRegistry()" --rpc-url $RPC_URL
cast call $TOKEN "trustedIssuersRegistry()" --rpc-url $RPC_URL
```

---

## Identity Management

### Crear Identity

```bash
IDENTITY_FACTORY=0x5FbDB2315678afecb367f032d93F642f64180aa3
IDENTITY_OWNER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Crear nueva identity
cast send $IDENTITY_FACTORY \
  "createIdentity(address)" \
  $IDENTITY_OWNER \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Ver todas las identities creadas
cast call $IDENTITY_FACTORY "getTotalIdentities()" --rpc-url $RPC_URL
```

### Registrar Identity

```bash
IDENTITY_REGISTRY=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
WALLET_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
IDENTITY_ADDRESS=0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968

# Registrar identity para una wallet
cast send $IDENTITY_REGISTRY \
  "registerIdentity(address,address)" \
  $WALLET_ADDRESS \
  $IDENTITY_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Verificar registro
cast call $IDENTITY_REGISTRY "isRegistered(address)" $WALLET_ADDRESS --rpc-url $RPC_URL

# Obtener identity de una wallet
cast call $IDENTITY_REGISTRY "getIdentity(address)" $WALLET_ADDRESS --rpc-url $RPC_URL
```

### Añadir Claim a Identity

```bash
IDENTITY=0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968
ISSUER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Claim topic IDs:
# 1 = KYC
# 2 = AML
# 3 = Accredited Investor

# Añadir claim (ej: KYC)
cast send $IDENTITY \
  "addClaim(uint256,uint256,address,bytes,bytes,string)" \
  1 \
  1 \
  $ISSUER \
  0x \
  0x \
  "" \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## Trusted Issuers

### Añadir Trusted Issuer

```bash
TRUSTED_REGISTRY=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
ISSUER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Claim topics que puede emitir (array)
# Ejemplo: [1, 2] = KYC y AML
cast send $TRUSTED_REGISTRY \
  "addTrustedIssuer(address,uint256[])" \
  $ISSUER_ADDRESS \
  "[1,2]" \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

### Ver Trusted Issuers

```bash
TRUSTED_REGISTRY=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

# Contar issuers
cast call $TRUSTED_REGISTRY "getTrustedIssuersCount()" --rpc-url $RPC_URL

# Ver todos los issuers
cast call $TRUSTED_REGISTRY "getTrustedIssuers()" --rpc-url $RPC_URL

# Verificar si es trusted
cast call $TRUSTED_REGISTRY "isTrustedIssuer(address)" $ISSUER --rpc-url $RPC_URL

# Ver claim topics de un issuer
cast call $TRUSTED_REGISTRY "getClaimTopics(address)" $ISSUER --rpc-url $RPC_URL
```

### Remover Trusted Issuer

```bash
cast send $TRUSTED_REGISTRY \
  "removeTrustedIssuer(address)" \
  $ISSUER_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## Verificación y Debugging

### Ver Información de Contrato

```bash
CONTRACT=0x...

# Ver código del contrato
cast code $CONTRACT --rpc-url $RPC_URL

# Ver owner
cast call $CONTRACT "owner()" --rpc-url $RPC_URL

# Ver si tiene una función
cast call $CONTRACT "supportsInterface(bytes4)" 0x01ffc9a7 --rpc-url $RPC_URL
```

### Ver Transacciones

```bash
# Ver receipt de una transacción
cast receipt $TX_HASH --rpc-url $RPC_URL

# Ver logs de una transacción
cast receipt $TX_HASH --json --rpc-url $RPC_URL | jq '.logs'

# Ver gas usado
cast receipt $TX_HASH --json --rpc-url $RPC_URL | jq '.gasUsed'
```

### Decodificar Data

```bash
# Decodificar function signature
cast sig "transfer(address,uint256)"
# Output: 0xa9059cbb

# Decodificar calldata
cast 4byte 0xa9059cbb
# Output: transfer(address,uint256)

# Decodificar log data
cast abi-decode "Transfer(address,address,uint256)" $LOG_DATA
```

### Estimación de Gas

```bash
# Estimar gas para una función
cast estimate $CONTRACT \
  "transfer(address,uint256)" \
  $RECIPIENT \
  1000000000000000000000 \
  --rpc-url $RPC_URL \
  --from $SENDER
```

### Ver Eventos

```bash
# Ver eventos de un contrato
cast logs --address $TOKEN --from-block 0 --to-block latest --rpc-url $RPC_URL

# Filtrar eventos Transfer
cast logs \
  --address $TOKEN \
  --sig "Transfer(address,address,uint256)" \
  --from-block 0 \
  --rpc-url $RPC_URL
```

---

## Variables de Entorno

### Cuentas de Anvil

```bash
# Account #0 (Default Admin)
export ACCOUNT_0=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export PRIVATE_KEY_0=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Account #1
export ACCOUNT_1=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
export PRIVATE_KEY_1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# Account #2
export ACCOUNT_2=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
export PRIVATE_KEY_2=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
```

### Direcciones de Contratos (Ejemplo de Deployment)

```bash
# Factories
export IDENTITY_FACTORY=0x5FbDB2315678afecb367f032d93F642f64180aa3
export TOKEN_FACTORY=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9

# Registries
export IDENTITY_REGISTRY=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export TRUSTED_REGISTRY=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

# Compliance Modules
export MAX_BALANCE=0x7fa9385be102ac3eac297483dd6233d62b3e1496
export MAX_HOLDERS=0x34a1d3fff3958843c43ad80f30b94c510645c316
export TRANSFER_LOCK=0x90193c961a926261b756d1e5bb255e67ff9498a1

# Token
export TOKEN=0x6D544390Eb535d61e196c87d6B9c80dCD8628Acd
```

### Archivo .env (Opcional)

Crear archivo `.env`:

```bash
# .env
RPC_URL=http://localhost:8545
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ETHERSCAN_API_KEY=your_key_here

# Contracts
TOKEN_FACTORY=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
IDENTITY_REGISTRY=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
TRUSTED_REGISTRY=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

Cargar en terminal:

```bash
source .env
```

---

## 🔥 Comandos Útiles Adicionales

### Conversión de Unidades

```bash
# Wei a Ether
cast --to-unit 1000000000000000000 ether
# Output: 1

# Ether a Wei
cast --to-wei 1 ether
# Output: 1000000000000000000

# Hex a decimal
cast --to-dec 0x64
# Output: 100

# Decimal a hex
cast --to-hex 100
# Output: 0x64
```

### Calcular Hashes

```bash
# Keccak256
cast keccak "Hello World"

# Selector de función
cast sig "transfer(address,uint256)"
```

### Inspeccionar Blockchain

```bash
# Bloque actual
cast block-number --rpc-url $RPC_URL

# Info del bloque
cast block latest --rpc-url $RPC_URL

# Balance de cuenta
cast balance $ACCOUNT --rpc-url $RPC_URL

# Nonce de cuenta
cast nonce $ACCOUNT --rpc-url $RPC_URL

# Chain ID
cast chain-id --rpc-url $RPC_URL
```

### Formateo

```bash
# Formatear código Solidity
forge fmt

# Verificar formato
forge fmt --check
```

---

## 📝 Scripts Personalizados

### Crear Script de Setup

```bash
#!/bin/bash
# setup.sh

# Cargar variables
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export RPC_URL=http://localhost:8545

# Desplegar sistema completo
./scripts/deploy-complete-auto.sh

# Guardar direcciones
echo "Setup completo!"
```

### Script de Test Rápido

```bash
#!/bin/bash
# quick-test.sh

cd sc
forge test --match-contract MaxBalanceCompliance -vv
forge test --match-contract MaxHoldersCompliance -vv
forge test --match-contract TransferLockCompliance -vv
```

---

## 🆘 Troubleshooting

### Error: "Invalid project"

```bash
# Asegurarse de estar en el directorio correcto
cd sc
pwd  # Debe mostrar .../56_RWA_SC/sc
```

### Error: "Connection refused"

```bash
# Verificar que Anvil está corriendo
ps aux | grep anvil

# Si no está, iniciarlo
anvil
```

### Error: "Nonce too low"

```bash
# Reset de nonce (en Anvil, reiniciar)
pkill anvil
anvil
```

### Ver Gas Price

```bash
cast gas-price --rpc-url $RPC_URL
```

---

## 📚 Recursos

- **Documentación Foundry:** https://book.getfoundry.sh/
- **Cast Reference:** https://book.getfoundry.sh/reference/cast/
- **Forge Reference:** https://book.getfoundry.sh/reference/forge/

---

**💡 Tip:** Guarda este archivo como referencia rápida. Usa `Ctrl+F` para buscar comandos específicos.

